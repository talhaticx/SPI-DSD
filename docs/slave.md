# ADXL362

3 - axis accelerometer

## ADXL362 Register Map

| Address | Name | Bits |  Description | Reset | R/W  |
|---------|------|------|--------------|-------|------|
| 0x08| XDATA| [7:0]| 8-bitX-AxisData| 0x00| R|
| 0x09| YDATA| [7:0]| 8-bitY-AxisData| 0x00| R|
| 0x0A| ZDATA| [7:0]| 8-bitZ-AxisData| 0x00| R|
| 0x0B| STATUS| [7:0]| ERR_USER,AWAKE,ACT,FIFO_OVERRUNetc.| 0x40| R|
| 0x0C| FIFO_ENTRIES_L| [7:0]| FIFOEntryCount(Low)| 0x00| R|
| 0x0D| FIFO_ENTRIES_H| [1:0]| FIFOEntryCount(High)| 0x00| R|
| 0x1F| SOFT_RESET| [7:0]| ResetRegister(Write0x52)| 0x00| W|
| 0x2C| FILTER_CTL| [7:0]| Range,Bandwidth,ODRsettings| 0x13| RW|
| 0x2D| POWER_CTL| [7:0]| MeasurementMode&PowerControl| 0x00| RW|

### SOFT RESET REGISTER

**Address: 0x1F, Reset: 0x00, Name: SOFT_RESET**
Writing Code `0x52` (representing the letter, `R`, in ASCII or unicode) to this register immediately resets the ADXL362. All register settings are cleared, and the sensor is placed in standby.

This is a write-only register. If read, data in it is always `0x00`.

### FILTER CONTROL REGISTER

**Address: 0x2C, Reset: 0x13, Name: FILTER_CTL**

`B[7:6]`: RANGE Measurement Range Selection.

|Data|Range|
|-|-|
|00 | ±2 g (reset default)|
|01 |±4 g|
|1X |±8 g|

### POWER CONTROL REGISTER
**Address: 0x2D, Reset: 0x00, Name: POWER_CTL**

| **Bits** | **Bit Name**     | **Settings**                                                                 | **Description**                                                                                   | **Reset** | **Access** |
|----------|------------------|------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|-----------|------------|
| 7        | Reserved         | Reserved.                                                                    | Reserved, set to 0.                                                                                | 0x0       | RW         |
| 6        | EXT_CLK          | 1 = External clock from INT1 pin. 0 = Internal clock.                        | Selects whether the accelerometer uses an external clock or its internal clock.                   | 0x0       | RW         |
| 5:4      | LOW_NOISE        | 00 = Normal operation, 01 = Low noise mode, 10 = Ultra-low noise, 11 = Reserved | Controls power vs. noise tradeoff: Normal operation (default), Low noise, Ultra-low noise modes.   | 0x0       | RW         |
| 3        | WAKEUP           | 1 = Wake-up mode enabled, 0 = Normal operation.                              | Determines if the accelerometer operates in wake-up mode for power saving.                         | 0x0       | RW         |
| 2        | AUTOSLEEP        | 1 = Autosleep enabled, 0 = Disabled.                                         | Enables automatic wake-up mode when inactivity is detected (linked/loop mode must be active).      | 0x0       | RW         |
| 1:0      | MEASURE          | 00 = Standby, 10 = Measurement mode, 01 = Reserved, 11 = Reserved            | Selects between standby mode (low power) and measurement mode (active data measurement).            | 0x0       | RW         |
