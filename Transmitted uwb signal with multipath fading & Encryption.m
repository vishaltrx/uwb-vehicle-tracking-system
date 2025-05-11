% Original Message Components
UIN = 'Car123';
speed = 80.5;
timestamp = '12:30:45';
message = sprintf('%s|Speed:%.1f|Timestamp:%s', UIN, speed, timestamp); % Full message

% Convert Message to Binary Sequence
binary_seq = reshape(dec2bin(message, 8).'-'0', 1, []); % Convert ASCII to binary
disp('Binary Representation of Original Message:');
disp(binary_seq);

% XOR Encryption Key (Random Binary Key)
rng(42); % Seed for reproducibility
encryption_key = randi([0, 1], 1, length(binary_seq)); % Generate random binary key
disp('Encryption Key:');
disp(encryption_key);

% XOR Encryption
encrypted_binary_seq = xor(binary_seq, encryption_key);
disp('Encrypted Binary Sequence:');
disp(encrypted_binary_seq);

% UWB Signal Parameters
fs = 6489.6e6;           % Sampling frequency (~6489.6 MHz)
bandwidth = 499.2e6;     % Bandwidth in Hz
pulse_duration = 1 / bandwidth; % Pulse duration in seconds
bit_duration = 1e-6;     % Bit duration (1 µs)
samples_per_pulse = round(fs * pulse_duration); % Samples per pulse
samples_per_bit = round(fs * bit_duration);    % Samples per bit
t_pulse = linspace(-pulse_duration/2, pulse_duration/2, samples_per_pulse);

% Generate Gaussian Pulse for UWB
gaussian_pulse = exp(-t_pulse.^2 / (2 * (pulse_duration / 6)^2)); % Short Gaussian pulse

% Modulate UWB Signal
uwb_signal = [];
for bit = encrypted_binary_seq
    if bit == 1
        uwb_bit = [gaussian_pulse, zeros(1, samples_per_bit - samples_per_pulse)];
    else
        uwb_bit = [zeros(1, samples_per_bit)]; % No pulse for binary 0
    end
    uwb_signal = [uwb_signal uwb_bit];
end

% Multipath Channel Parameters
num_paths = 3; % Number of multipath components
path_delays = [0, 50e-9, 100e-9]; % Larger delays to emphasize multipath
path_gains = [1.0, 0.7, 0.4];    % Relative gains for each path

% Doppler Effect Parameters
relative_velocity = 30; % Relative velocity in m/s
carrier_frequency = 6489.6e6; % Carrier frequency in Hz
c = 3e8; % Speed of light in m/s
doppler_shift = (relative_velocity / c) * carrier_frequency; % Doppler shift in Hz

% Time-Varying Multipath Channel Modeling
t = (0:length(uwb_signal)-1) / fs;
time_varying_signal = zeros(size(uwb_signal));

for p = 1:num_paths
    delay_samples = round(path_delays(p) * fs);
    doppler_effect = exp(1j * 2 * pi * doppler_shift * t);
    attenuated_signal = [zeros(1, delay_samples), uwb_signal(1:end-delay_samples)] * path_gains(p);
    time_varying_signal = time_varying_signal + real(attenuated_signal .* doppler_effect);
end

% Add Gaussian Noise
SNR = 5; % Lower SNR to make noise more visible
received_signal = awgn(time_varying_signal, SNR, 'measured');

% Decode Received Signal
decoded_bits = [];
for i = 1:length(encrypted_binary_seq)
    bit_segment = received_signal((i-1)*samples_per_bit + 1 : i*samples_per_bit);
    correlation = conv(bit_segment, fliplr(gaussian_pulse), 'valid');
    if max(correlation) > 0.5 * max(conv(gaussian_pulse, fliplr(gaussian_pulse), 'valid'))
        decoded_bits = [decoded_bits 1];
    else
        decoded_bits = [decoded_bits 0];
    end
end

% XOR Decryption
decrypted_binary_seq = xor(decoded_bits, encryption_key);

% Reshape Binary Sequence to 8-Bit Segments
binary_matrix = reshape(decrypted_binary_seq, 8, []).';
received_message = char(bin2dec(num2str(binary_matrix)))';

% Display Results
disp(['Original Message: ', message]);
disp(['Decoded Message: ', received_message]);

% Plot Signals (Zoomed-In View)
zoom_samples = 1:min(2*samples_per_bit, length(uwb_signal));

figure;
subplot(3, 1, 1);
plot(zoom_samples, uwb_signal(zoom_samples), 'LineWidth', 1.5);
title('Transmitted UWB Signal (Zoomed)');
xlabel('Samples'); ylabel('Amplitude');

subplot(3, 1, 2);
plot(zoom_samples, time_varying_signal(zoom_samples), 'LineWidth', 1.5);
title('UWB Signal with Multipath and Doppler Effects (Zoomed)');
xlabel('Samples'); ylabel('Amplitude');

subplot(3, 1, 3);
plot(zoom_samples, received_signal(zoom_samples), 'LineWidth', 1.5);
title('Received UWB Signal with Noise (Zoomed)');
xlabel('Samples'); ylabel('Amplitude');

% Frequency Domain Analysis
freq_axis = linspace(-fs/2, fs/2, length(uwb_signal));
figure;
subplot(3, 1, 1);
plot(freq_axis, abs(fftshift(fft(uwb_signal))), 'LineWidth', 1.5);
title('Transmitted Signal Spectrum');
xlabel('Frequency (Hz)'); ylabel('Magnitude');

subplot(3, 1, 2);
plot(freq_axis, abs(fftshift(fft(time_varying_signal))), 'LineWidth', 1.5);
title('Multipath-Affected Signal Spectrum');
xlabel('Frequency (Hz)'); ylabel('Magnitude');

subplot(3, 1, 3);
plot(freq_axis, abs(fftshift(fft(received_signal))), 'LineWidth', 1.5);
title('Received Signal Spectrum');
xlabel('Frequency (Hz)'); ylabel('Magnitude');

% Cross-Correlation Analysis
correlation = xcorr(received_signal, uwb_signal);
figure;
plot(correlation, 'LineWidth', 1.5);
title('Cross-Correlation of Transmitted and Received Signals');
xlabel('Lag'); ylabel('Correlation');
