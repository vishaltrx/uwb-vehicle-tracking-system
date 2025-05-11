---

## 🔁 System Flow

1. **Vehicle Transmitter** (ESP32 + DW1000):

   * Generates a unique ID (UIN), speed value, and timestamp
   * Encrypts the message using XOR
   * Transmits over UWB at 6489.6 MHz

2. **Receiver Node**:

   * Decrypts and parses data
   * Filters based on urgency/delay
   * Sends data to ThingSpeak cloud via ESP32 Wi-Fi

3. **MATLAB Simulation**:

   * Encrypts + modulates UWB signal
   * Applies multipath, Doppler, and Gaussian noise
   * Recovers data via matched filtering
   * Validates antenna efficiency, power budget, and BER

---

## 📈 Simulation Highlights

* **Multipath propagation** with 3 reflections
* **Rician channel** with tunable K-factor
* **Doppler shift** for moving nodes
* **BER calculation** under noisy, fading conditions
* **Cross-correlation** for signal integrity validation

---

## 📡 Antenna Optimization

* Designed a **planar monopole antenna** using Rogers RT5880 substrate
* Tuned for **Channel 5 (6489.6 MHz)** with high gain and low S11
* Simulated **vertical, horizontal, and tilted orientations**
* Output: Gain, radiation pattern, efficiency, received power

---

## 📊 Delay Formula Comparison

* Formula: `delay = range / (n × speed)`
* Compared throughput vs fixed-interval transmission
* Result: Formula-based scheduling reduces collisions and increases efficiency in dense networks

---

## 👨‍🎓 Author

**Vishal Suresh**
MSc Electrical and Electronic Engineering
University of Greenwich (2024)
Supervisor: Mr. Kamran Pedram

---

## 📜 License

This project is released under the [MIT License](LICENSE).
