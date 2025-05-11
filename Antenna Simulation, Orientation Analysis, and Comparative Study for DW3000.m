clc; clear; close all;

% --------------------------- UWB Signal Parameters ---------------------------
fs = 20e9;           % Sampling frequency (20 GHz)
center_freq = 6.5e9; % Center frequency in Hz
bandwidth = 499.2e6; % Bandwidth in Hz
pulse_duration = 1 / bandwidth; % Pulse duration in seconds
bit_duration = 1e-6; % Bit duration (1 microsecond)
samples_per_pulse = round(fs * pulse_duration); % Samples per pulse
samples_per_bit = round(fs * bit_duration);    % Samples per bit

% Generate Time Vector for Pulse
t_pulse = linspace(-pulse_duration/2, pulse_duration/2, samples_per_pulse);

% Generate Gaussian Pulse for UWB
sigma = pulse_duration / 6; % Gaussian pulse width parameter
gaussian_pulse = exp(-t_pulse.^2 / (2 * sigma^2));
gaussian_pulse = gaussian_pulse / max(abs(gaussian_pulse)); % Normalize pulse

% Define Binary Sequence to Transmit
binary_seq = [1 0 1 1 0 1 0 1 1 0];

% Modulate UWB Signal
uwb_signal = [];
for bit = binary_seq
    if bit == 1
        % Pulse for binary 1
        uwb_bit = [gaussian_pulse, zeros(1, samples_per_bit - samples_per_pulse)];
    else
        % No pulse for binary 0
        uwb_bit = zeros(1, samples_per_bit);
    end
    uwb_signal = [uwb_signal, uwb_bit];
end

% Normalize Transmitted Signal
uwb_signal = uwb_signal / max(abs(uwb_signal));

% --------------------------- Antenna Integration ---------------------------
% Antenna Design Parameters
groundPlaneSize = 30e-3; % 30 mm x 30 mm
innerRadius = 6e-3;      % Inner radius of annular radiator (6 mm)
outerRadius = 14e-3;     % Outer radius of annular radiator (14 mm)

% Define Dielectric Substrate
substrate = dielectric('Name', 'RogersRT5880', 'EpsilonR', 2.2, 'LossTangent', 0.0009);
substrate.Thickness = 1.6e-3; % 1.6 mm thickness

% Define Annular Radiator
outerCircle = antenna.Circle('Radius', outerRadius, 'Center', [0, 0]);
innerCircle = antenna.Circle('Radius', innerRadius, 'Center', [0, 0]);
radiator = outerCircle - innerCircle; % Annular radiator

% Define Ground Plane
groundPlane = antenna.Rectangle('Length', groundPlaneSize, 'Width', groundPlaneSize, 'Center', [0, 0]);

% Create Antenna Structure
ant = pcbStack;
ant.BoardThickness = substrate.Thickness;
ant.BoardShape = groundPlane;
ant.Layers = {radiator, substrate, groundPlane};

% Corrected Feed Location
feed_x = (innerRadius + outerRadius) / 2; % Midpoint of annular radiator
feed_y = 0; % Along the X-axis
ant.FeedLocations = [feed_x, feed_y, 1, 3]; % Connect radiator and ground

% Visualize Antenna
figure;
show(ant);
title('Optimized Planar Monopole Antenna for DW3000 with Low-Loss Substrate');

% Mesh the Antenna
try
    mesh(ant, 'MaxEdgeLength', 0.005); % Fine mesh for better accuracy
catch ME
    disp('Error during meshing:');
    disp(ME.message);
end

% Simulate S-Parameters
freq_range = linspace(6e9, 10e9, 50); % Frequency range: 6-10 GHz
try
    spar = sparameters(ant, freq_range);
    figure;
    rfplot(spar);
    title('S-Parameters of Optimized Planar Monopole Antenna');
    % Use S11 for Reflection Loss
    reflection_loss = 10.^(-abs(squeeze(spar.Parameters(1, 1, :))) / 10); % Convert dB to linear
catch ME
    disp('Error during S-parameter simulation:');
    disp(ME.message);
    reflection_loss = 1; % Default to maximum loss if error occurs
end

% Apply Reflection Loss to UWB Signal
uwb_signal = uwb_signal * sqrt(1 - reflection_loss(1));

% --------------------------- Efficiency Metrics ---------------------------
try
    radiation_efficiency = 0.95; % Assume 95% radiation efficiency for example
    antenna_efficiency = (1 - reflection_loss(1)) * radiation_efficiency;
    fprintf('Antenna Efficiency: %.2f%%\n', antenna_efficiency * 100);
catch ME
    disp('Error during efficiency calculation:');
    disp(ME.message);
end

% --------------------------- Gain and Directivity ---------------------------
try
    figure;
    pattern(ant, center_freq);
    title('Antenna Radiation Pattern at 6.5 GHz (Gain and Directivity)');
    % Export Gain Data
    gain = pattern(ant, center_freq);
    fprintf('Maximum Gain: %.2f dB\n', max(gain(:)));
catch ME
    disp('Error during gain and directivity analysis:');
    disp(ME.message);
end

% --------------------------- Orientation Studies ---------------------------
orientations = {'Vertical', 'Horizontal', 'Tilted'};
gains = zeros(1, 3);
received_powers = zeros(1, 3);

for i = 1:3
    % Set orientation
    switch orientations{i}
        case 'Vertical'
            disp('Simulating Vertical Orientation...');
            % Default orientation, no rotation needed
        case 'Horizontal'
            disp('Simulating Horizontal Orientation...');
            try
                gain_horizontal = patternElevation(ant, center_freq, 0);
                gains(i) = max(gain_horizontal(:));
            catch ME
                disp('Error during horizontal orientation simulation:');
                disp(ME.message);
                continue;
            end
        case 'Tilted'
            disp('Simulating Tilted Orientation...');
            try
                gain_tilted = patternElevation(ant, center_freq, 45);
                gains(i) = max(gain_tilted(:));
            catch ME
                disp('Error during tilted orientation simulation:');
                disp(ME.message);
                continue;
            end
    end

    % Calculate received power
    transmitted_power = mean(abs(uwb_signal).^2); % Transmitted Power
    received_powers(i) = transmitted_power * (10^(gains(i) / 10)) * antenna_efficiency;
    fprintf('Received Power for %s Orientation: %.4f W\n', orientations{i}, received_powers(i));
end

% Display results
orientation_results = table(orientations', gains', received_powers', ...
    'VariableNames', {'Orientation', 'MaxGain_dB', 'ReceivedPower_W'});
disp(orientation_results);

% --------------------------- Rician Multipath Channel ---------------------------
kFactor = 70; % Further increased K-factor for very strong LOS
ricianChan = comm.RicianChannel(...
    'SampleRate', fs, ...
    'PathDelays', [0, 50e-9, 100e-9], ... % Path delays in seconds
    'AveragePathGains', [0, -3, -6], ... % Path gains in dB
    'KFactor', kFactor, ...
    'MaximumDopplerShift', 5); % Reduced Doppler shift

% Apply Rician Fading Channel
faded_signal = ricianChan(uwb_signal.');

% Add Gaussian Noise
SNR = 60; % Further increased Signal-to-noise ratio in dB
received_signal = awgn(faded_signal, SNR, 'measured');

% --------------------------- Matched Filtering ---------------------------
matched_filter = fliplr(gaussian_pulse);
filtered_signal = conv(received_signal, matched_filter, 'same');

% Decoding Bits Using Matched Filter Output
decoded_bits = zeros(1, length(binary_seq));
threshold = max(abs(filtered_signal)) * 0.5; % Adaptive threshold

for i = 1:length(binary_seq)
    % Extract bit segment
    start_idx = (i-1)*samples_per_bit + 1;
    end_idx = i*samples_per_bit;
    bit_segment = filtered_signal(start_idx:end_idx);

    % Decision logic
    if max(abs(bit_segment)) > threshold
        decoded_bits(i) = 1;
    else
        decoded_bits(i) = 0;
    end
end

% --------------------------- Power Budget Validation ---------------------------
% Transmitted Power (Before Antenna)
transmitted_power = mean(abs(uwb_signal).^2);

% Reflected Power (Antenna S11)
reflection_coeff = reflection_loss(1); % From S11 parameter
reflected_power = transmitted_power * reflection_coeff;

% Received Power (After Channel and Noise)
received_power = mean(abs(received_signal).^2);

% Link Budget Validation
path_gain = sum(10.^(ricianChan.AveragePathGains / 10)); % Linear path gain
validated_received_power = transmitted_power * antenna_efficiency * path_gain;
fprintf('Validated Received Power: %.4f W\n', validated_received_power);

% --------------------------- Visualization ---------------------------
figure;
subplot(3, 1, 1);
plot(uwb_signal(1:2000), 'b');
title('Transmitted UWB Signal');
xlabel('Samples'); ylabel('Amplitude'); grid on;

subplot(3, 1, 2);
plot(received_signal(1:2000), 'r');
title('Received UWB Signal with Rician Fading and Noise');
xlabel('Samples'); ylabel('Amplitude'); grid on;

subplot(3, 1, 3);
plot(filtered_signal(1:2000), 'g');
title('Matched Filter Output (Zoomed)');
xlabel('Samples'); ylabel('Amplitude'); grid on;

% Visualize Radiation Pattern
try
    figure;
    pattern(ant, center_freq);
    title('Antenna Radiation Pattern at 6.5 GHz');
catch ME
    disp('Error during radiation pattern simulation:');
    disp(ME.message);
end

% --------------------------- Results ---------------------------
disp('Original Binary Sequence:');
disp(binary_seq);
disp('Decoded Binary Sequence:');
disp(decoded_bits);

% Calculate Bit Error Rate
bit_errors = sum(binary_seq ~= decoded_bits);
bit_error_rate = bit_errors / length(binary_seq);
fprintf('Bit Errors: %d\n', bit_errors);
fprintf('Bit Error Rate: %.2f%%\n', bit_error_rate * 100);


