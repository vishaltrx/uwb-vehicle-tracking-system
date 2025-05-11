#include <DW1000.h>

#define DW1000_CS_PIN 4   // Chip select pin
#define DW1000_RST_PIN 25 // Reset pin

unsigned long startMillis = 0; // To track time since the program started

void setup() {
  Serial.begin(115200);

  // Initialize DWM1000
  DW1000.begin(DW1000_CS_PIN, DW1000_RST_PIN);
  DW1000.select(DW1000_CS_PIN);
  DW1000.reset();

  // Configure DWM1000
  DW1000.setNetworkId(10);       // Network ID
  DW1000.setDeviceAddress(1);    // Unique device address for the transmitter
  
  // Set UWB Channel to 5
  DW1000.setChannel(5);          // Channel 5: 6489.6 MHz
  
  DW1000.enableMode(DW1000.MODE_SHORTDATA_FAST_ACCURACY);
  DW1000.commitConfiguration();

  startMillis = millis(); // Initialize the timer
}

String getFormattedTimestamp() {
  unsigned long elapsedMillis = millis() - startMillis; // Time since start in ms
  unsigned long totalSeconds = elapsedMillis / 1000;
  unsigned int hours = (totalSeconds / 3600) % 24;       // Hours (24-hour format)
  unsigned int minutes = (totalSeconds / 60) % 60;      // Minutes
  unsigned int seconds = totalSeconds % 60;             // Seconds

  char buffer[9]; // HH:MM:SS requires 8 chars + null terminator
  sprintf(buffer, "%02d:%02d:%02d", hours, minutes, seconds); // Format time
  return String(buffer);
}

void loop() {
  // Prepare the message
  String uin = "CAR_123";
  float speed = 0.05; // Example speed value
  String timestamp = getFormattedTimestamp();
  String message = uin + "," + String(speed, 2) + "," + timestamp;

  // Send the message
  DW1000.newTransmit();
  DW1000.setData((byte *)message.c_str(), message.length()); // Correct cast to byte
  DW1000.startTransmit();

  Serial.println("Message sent: " + message);

  delay(2000); // Wait for 2 seconds before sending the next message
}
