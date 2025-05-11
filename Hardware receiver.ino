#include <WiFi.h>                // Library for WiFi connectivity
#include <HTTPClient.h>          // Library to send HTTP requests
#include <DW1000.h>              // Library for DWM1000 UWB module

// WiFi credentials
const char* ssid = "BT-RTF9PT";              
const char* password = "fKP9TNHMYR7d7e";     

// ThingSpeak credentials
const char* thingSpeakURL = "http://api.thingspeak.com/update";
const String writeAPIKey = "3Y6QE9M2Z3KHZURT";  
#define DW1000_CS_PIN 4   // Chip select pin for DWM1000
#define DW1000_RST_PIN 25 // Reset pin for DWM1000

char receivedData[128];   // Buffer for received message
unsigned long lastUpdate = 0; // To manage ThingSpeak update rate

void setup() {
  Serial.begin(115200);

  // Initialize DWM1000 module
  DW1000.begin(DW1000_CS_PIN, DW1000_RST_PIN);
  DW1000.select(DW1000_CS_PIN);
  DW1000.reset();

  // Configure DWM1000
  DW1000.setNetworkId(10);      // Network ID
  DW1000.setDeviceAddress(2);   // Unique address for the receiver
  
  // Set UWB channel to 5 (or another desired channel)
  DW1000.setChannel(5);  // Channel selection (1 to 7 for DW1000)
  
  DW1000.enableMode(DW1000.MODE_SHORTDATA_FAST_ACCURACY);
  DW1000.commitConfiguration();

  DW1000.newReceive();
  DW1000.startReceive();

  // Connect to WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  // Check if data is received
  if (DW1000.isReceiveDone()) {
    DW1000.getData((byte *)receivedData, sizeof(receivedData));
    String message = String(receivedData);

    // Parse the message
    String uin, speed, timestamp;
    int firstComma = message.indexOf(',');
    int secondComma = message.indexOf(',', firstComma + 1);

    if (firstComma > 0 && secondComma > firstComma) {
      uin = message.substring(0, firstComma);
      speed = message.substring(firstComma + 1, secondComma);
      timestamp = message.substring(secondComma + 1);

      // Display parsed data in the desired format
      Serial.println("-----------------------------");
      Serial.println("Data received:");
      Serial.println("UIN: " + uin);
      Serial.println("Speed: " + speed + " L/min");
      Serial.println("Timestamp: " + timestamp);
      Serial.println("-----------------------------");

      // Send data to ThingSpeak every 15 seconds
      if (millis() - lastUpdate >= 15000) {
        sendDataToThingSpeak(uin, speed, timestamp);
        lastUpdate = millis();
      }
    } else {
      // Handle parsing errors
      Serial.println("Error parsing message");
    }

    // Prepare for the next reception
    DW1000.newReceive();
    DW1000.startReceive();
  }
}

// Function to send data to ThingSpeak
void sendDataToThingSpeak(String uin, String speed, String timestamp) {
  if (WiFi.status() == WL_CONNECTED) { // Check WiFi connection
    HTTPClient http;

    // Build the HTTP request URL
    String requestURL = String(thingSpeakURL) +
                        "?api_key=" + writeAPIKey +
                        "&field1=" + uin +
                        "&field2=" + speed +
                        "&field3=" + timestamp;

    http.begin(requestURL);      // Initialize the HTTP request
    int httpResponseCode = http.GET(); // Send GET request

    // Handle the response
    if (httpResponseCode > 0) {
      Serial.println("Data sent successfully to ThingSpeak.");
    } else {
      Serial.println("Error Sending Data: " + String(httpResponseCode));
    }

    http.end(); // End HTTP connection
  } else {
    Serial.println("WiFi not connected. Unable to send data to ThingSpeak.");
  }
} 
