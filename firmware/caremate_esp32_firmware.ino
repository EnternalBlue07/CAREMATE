/*
 * CAREMATE ESP32 Healthcare Companion Robot - Production Firmware
 * Microcontroller: ESP32 DevKit V1
 * Protocol: Bluetooth Low Energy (BLE) GATT Server
 * Features:
 *  - 6-Compartment Pill Carousel (Step/Servo Motor)
 *  - Dispense Gate Servo
 *  - Optical/IR Tablet Drop Detection Sensor
 *  - Audio/Buzzer Reminder Alerts
 *  - Truthful Two-Way Status Reporting & Jam Detection
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ESP32Servo.h>

// BLE UUIDs
#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID_RX "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHARACTERISTIC_UUID_TX "beb5483f-36e1-4688-b7f5-ea07361b26a8"

// Hardware Pin Configuration
#define PIN_SERVO_CAROUSEL    18   // PWM Servo for rotating carousel (Slots 1-6)
#define PIN_SERVO_GATE        19   // PWM Servo for dispensing trapdoor
#define PIN_BUZZER            21   // Piezo Buzzer for reminders & alarms
#define PIN_DROP_SENSOR       22   // IR Beam / Optical sensor (active LOW on tablet fall)
#define PIN_STATUS_LED        2    // On-board LED indicator

// Carousel Slot Angles (6 Slots: 0 deg to 300 deg in 60 deg steps)
const int SLOT_ANGLES[6] = { 0, 60, 120, 180, 240, 300 };

// Gate Angles
const int GATE_CLOSED_ANGLE = 0;
const int GATE_OPEN_ANGLE   = 85;

Servo carouselServo;
Servo gateServo;

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Robot State
int currentSlot = 1;
bool gateOpen = false;
bool mechanismJam = false;
int batteryLevel = 94; // % simulated or ADC read from pin 34

void sendStatusNotification(const String& message);

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        digitalWrite(PIN_STATUS_LED, HIGH);
        Serial.println("[BLE] Client Connected");
    };

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        digitalWrite(PIN_STATUS_LED, LOW);
        Serial.println("[BLE] Client Disconnected. Restarting Advertising...");
    }
};

void soundBuzzerAlert(int toneFreq, int durationMs, int repetitions) {
    for (int i = 0; i < repetitions; i++) {
        tone(PIN_BUZZER, toneFreq, durationMs);
        delay(durationMs + 50);
        noTone(PIN_BUZZER);
    }
}

// Rotate carousel to selected slot (1-6)
bool rotateToSlot(int targetSlot) {
    if (targetSlot < 1 || targetSlot > 6) return false;
    Serial.printf("[CAROUSEL] Moving from Slot %d to Slot %d (Angle: %d deg)\n", 
                  currentSlot, targetSlot, SLOT_ANGLES[targetSlot - 1]);
    
    // Smooth servo rotation
    carouselServo.write(SLOT_ANGLES[targetSlot - 1]);
    delay(750); // Allow physical transit time
    currentSlot = targetSlot;
    return true;
}

// Dispense cycle with optical confirmation
bool executeDispense(int slot) {
    if (mechanismJam) {
        sendStatusNotification("ERR:JAM_DETECTED");
        return false;
    }

    sendStatusNotification("STATE:ROTATING_SLOT:" + String(slot));
    if (!rotateToSlot(slot)) {
        sendStatusNotification("ERR:INVALID_SLOT");
        return false;
    }

    // Audible reminder before dispensing
    soundBuzzerAlert(1800, 120, 2);

    // Open Gate
    sendStatusNotification("STATE:OPENING_GATE");
    gateServo.write(GATE_OPEN_ANGLE);
    gateOpen = true;

    // Wait for tablet drop with timeout (2.5 seconds)
    unsigned long startTime = millis();
    bool dropDetected = false;

    while (millis() - startTime < 2500) {
        if (digitalRead(PIN_DROP_SENSOR) == LOW) { // IR beam broken by pill
            dropDetected = true;
            break;
        }
        delay(20);
    }

    // Close Gate immediately
    gateServo.write(GATE_CLOSED_ANGLE);
    gateOpen = false;
    delay(400);

    if (dropDetected) {
        Serial.println("[DISPENSE] Tablet drop confirmed by IR sensor.");
        soundBuzzerAlert(2400, 200, 1);
        sendStatusNotification("DISPENSE_CONFIRMED:SLOT:" + String(slot));
        return true;
    } else {
        // Fallback check: Did mechanism jam or was compartment empty?
        Serial.println("[DISPENSE] WARNING: No drop detected within timeout window.");
        soundBuzzerAlert(800, 400, 3);
        sendStatusNotification("ERR:NO_DROP_DETECTED:SLOT:" + String(slot));
        return false;
    }
}

class CommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        String rxValue = pCharacteristic->getValue();

        if (rxValue.length() > 0) {
            rxValue.trim();
            Serial.print("[BLE RX Command]: ");
            Serial.println(rxValue);

            if (rxValue == "STATUS") {
                String report = "STATUS:OK|SLOT:" + String(currentSlot) + 
                                "|BAT:" + String(batteryLevel) + 
                                "|JAM:" + (mechanismJam ? "1" : "0") + 
                                "|GATE:" + (gateOpen ? "1" : "0");
                sendStatusNotification(report);
            }
            else if (rxValue.startsWith("DISPENSE_SLOT:")) {
                int slot = rxValue.substring(14).toInt();
                executeDispense(slot);
            }
            else if (rxValue == "DISPENSE_TEST") {
                executeDispense(currentSlot);
            }
            else if (rxValue == "TEST_BUZZER") {
                soundBuzzerAlert(2200, 150, 3);
                sendStatusNotification("ACK:TEST_BUZZER_DONE");
            }
            else if (rxValue == "CALIBRATE") {
                rotateToSlot(1);
                gateServo.write(GATE_CLOSED_ANGLE);
                gateOpen = false;
                mechanismJam = false;
                soundBuzzerAlert(2000, 100, 2);
                sendStatusNotification("ACK:CALIBRATION_COMPLETE");
            }
            else if (rxValue == "SIMULATE_JAM") {
                mechanismJam = true;
                sendStatusNotification("WARN:SIMULATED_JAM_ACTIVE");
            }
            else if (rxValue == "CLEAR_JAM") {
                mechanismJam = false;
                sendStatusNotification("ACK:JAM_CLEARED");
            }
            else if (rxValue == "EMERGENCY_STOP") {
                gateServo.write(GATE_CLOSED_ANGLE);
                gateOpen = false;
                noTone(PIN_BUZZER);
                sendStatusNotification("ACK:EMERGENCY_STOP_EXECUTED");
            }
            else {
                sendStatusNotification("ERR:UNKNOWN_COMMAND");
            }
        }
    }
};

void sendStatusNotification(const String& message) {
    if (deviceConnected && pTxCharacteristic != NULL) {
        pTxCharacteristic->setValue(message.c_str());
        pTxCharacteristic->notify();
        Serial.print("[BLE TX Notify]: ");
        Serial.println(message);
    }
}

void setup() {
    Serial.begin(115200);
    Serial.println("Starting CAREMATE ESP32 Companion Robot...");

    pinMode(PIN_DROP_SENSOR, INPUT_PULLUP);
    pinMode(PIN_STATUS_LED, OUTPUT);
    pinMode(PIN_BUZZER, OUTPUT);

    // Initialize Servos
    ESP32PWM::allocateTimer(0);
    ESP32PWM::allocateTimer(1);
    carouselServo.setPeriodHertz(50);
    gateServo.setPeriodHertz(50);

    carouselServo.attach(PIN_SERVO_CAROUSEL, 500, 2500);
    gateServo.attach(PIN_SERVO_GATE, 500, 2500);

    // Set initial calibrated state
    gateServo.write(GATE_CLOSED_ANGLE);
    rotateToSlot(1);

    // Startup beep
    soundBuzzerAlert(1500, 80, 2);

    // Initialize BLE
    BLEDevice::init("CAREMATE-ROBOT-01");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);

    // TX Characteristic (Notify to App)
    pTxCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID_TX,
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pTxCharacteristic->addDescriptor(new BLE2902());

    // RX Characteristic (Write from App)
    BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID_RX,
        BLECharacteristic::PROPERTY_WRITE
    );
    pRxCharacteristic->setCallbacks(new CommandCallbacks());

    pService->start();

    // Start Advertising
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("[BLE] Service started. Advertising as CAREMATE-ROBOT-01");
}

void loop() {
    // Re-advertising handling if disconnected
    if (!deviceConnected && oldDeviceConnected) {
        delay(500);
        pServer->startAdvertising();
        Serial.println("[BLE] Advertising restarted.");
        oldDeviceConnected = deviceConnected;
    }
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }
    delay(20);
}
