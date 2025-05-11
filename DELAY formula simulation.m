clc; clear; close all;

% Parameters
roadLength = 100;               % Length of the road (units)
vehicleSpeeds = [10, 20, 30];   % Speeds of each vehicle (units per step)
numVehicles = length(vehicleSpeeds); % Number of vehicles
receiverPos = 50;               % Position of the receiver
detectionRange = 20;            % Receiver detection range
n = 2;                          % Number of transmissions per vehicle

% Initialize vehicle positions
vehiclePositions = rand(1, numVehicles) * roadLength; % Random starting positions
UINs = {'V001', 'V002', 'V003'};                      % Unique IDs for vehicles

% Simulation parameters
totalTimeSteps = 100;          % Total simulation time steps
timeStepDuration = 1;          % Duration of each time step (s)
throughput = 0;                % Track the number of successful transmissions
throughputWithoutFormula = 0;  % Throughput without using the formula

% Initialize figure
figure;
hold on;
axis([0 roadLength -10 10]); % Set plot limits
title('Real-Time UWB Vehicle Tracking');
xlabel('Road Length');
ylabel('Position');

% Plot receiver
plot(receiverPos, 0, 'bs', 'MarkerSize', 12, 'MarkerFaceColor', 'b'); % Receiver
rectangle('Position', [receiverPos-detectionRange -detectionRange detectionRange*2 detectionRange*2], ...
          'Curvature', [1 1], 'EdgeColor', 'b', 'LineStyle', '--'); % Detection range

% Simulation loop
for t = 1:totalTimeSteps
    cla; % Clear the figure

    % Plot the receiver
    plot(receiverPos, 0, 'bs', 'MarkerSize', 12, 'MarkerFaceColor', 'b'); % Receiver
    rectangle('Position', [receiverPos-detectionRange -detectionRange detectionRange*2 detectionRange*2], ...
              'Curvature', [1 1], 'EdgeColor', 'b', 'LineStyle', '--'); % Detection range

    % Loop through each vehicle
    for i = 1:numVehicles
        % Update vehicle position
        vehiclePositions(i) = vehiclePositions(i) + vehicleSpeeds(i) * timeStepDuration;

        % Reset position if vehicle crosses the road length
        if vehiclePositions(i) > roadLength
            vehiclePositions(i) = 0; % Reset position
        end

        % Plot the vehicle
        plot(vehiclePositions(i), 0, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        text(vehiclePositions(i), 1, UINs{i}, 'HorizontalAlignment', 'center', 'FontSize', 10);

        % Check if the vehicle is in range of the receiver
        if abs(vehiclePositions(i) - receiverPos) <= detectionRange
            % Calculate delay using the formula
            delay = detectionRange / (n * vehicleSpeeds(i));

            % Check if transmission is successful using the delay
            if mod(t, round(delay)) == 0
                % Transmission successful (using formula)
                throughput = throughput + 1;
                plot([vehiclePositions(i) receiverPos], [0 0], 'g-', 'LineWidth', 2); % Signal line
                disp(['[Using Formula] Transmission from ', UINs{i}, ...
                      ' | Speed: ', num2str(vehicleSpeeds(i)), ...
                      ' units/s | Delay: ', num2str(delay, '%.2f'), 's']);
            end

            % Simulate naive transmission without formula
            if mod(t, 5) == 0 % Fixed delay of 5 time steps
                throughputWithoutFormula = throughputWithoutFormula + 1;
                plot([vehiclePositions(i) receiverPos], [0 0], 'r-', 'LineWidth', 1); % Signal line without formula
                disp(['[Without Formula] Transmission from ', UINs{i}, ...
                      ' | Speed: ', num2str(vehicleSpeeds(i)), ' units/s']);
            end
        end
    end

    pause(0.2); % Pause for better visualization
end

% Display throughput results
disp('--- Simulation Results ---');
disp(['Total Successful Transmissions (Using Formula): ', num2str(throughput)]);
disp(['Total Successful Transmissions (Without Formula): ', num2str(throughputWithoutFormula)]);

