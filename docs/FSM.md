# FSM Module Documentation

This module implements a **Finite State Machine (FSM)** that manages SPI communication with an external device (e.g., an accelerometer), handling data selection, SPI transfer control, and chip select logic.

---

## Inputs

| Signal  | Width | Description                    |
| ------- | ----- | ------------------------------ |
| `clk`   | 1 bit | System clock                   |
| `power` | 1 bit | Power ON/OFF switch            |
| `done`  | 1 bit | SPI transfer completion signal |

---

## Outputs

| Signal        | Width  | Description                 |
| ------------- | ------ | --------------------------- |
| `data_select` | 2 bits | SPI command selector        |
| `transfer`    | 1 bit  | Enable MOSI transfer        |
| `receive`     | 1 bit  | Enable MISO reception       |
| `cs`          | 1 bit  | Chip Select (active LOW)    |
| `data_size`   | 3 bits | Number of bytes to transfer |

---

## FSM States

```verilog
typedef enum logic [2:0] {
    IDLE,             // 000: Wait for power
    MEASUREMENT_MODE, // 001: Send measurement command
    SEND,             // 010: Send SPI data
    RECEIVE,          // 011: Receive SPI data
    SOFT_RST          // 100: Soft reset on power off
} state_t;
```

---

## State Transitions

| Current State      | Condition    | Next State         |
| ------------------ | ------------ | ------------------ |
| `IDLE`             | `power == 1` | `MEASUREMENT_MODE` |
| `MEASUREMENT_MODE` | `done == 1`  | `SEND`             |
| `SEND`             | `done == 1`  | `RECEIVE`          |
| `RECEIVE`          | `done == 1`  | `SEND`             |
| *Any*              | `power == 0` | `SOFT_RST`         |
| `SOFT_RST`         | `done == 1`  | `IDLE`             |

---

## Output Logic per State

| State              | `data_select` | `transfer` | `receive` | `data_size` |
| ------------------ | ------------- | ---------- | --------- | ----------- |
| `IDLE`             | `00`          | `0`        | `0`       | `0`         |
| `MEASUREMENT_MODE` | `01`          | `1`        | `0`       | `3`         |
| `SEND`             | `10`          | `1`        | `0`       | `2`         |
| `RECEIVE`          | `00`          | `1`        | `1`       | `3`         |
| `SOFT_RST`         | `11`          | `1`        | `0`       | `3`         |

---

## CS (Chip Select) Behavior

- Default high (`1`) in `IDLE`
- **Deasserted (********`1`********\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*)** after `MEASUREMENT_MODE` command is done
- **Asserted (********`0`********\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*)** at `SEND`
- **Toggled** during `SOFT_RST`

---

## Summary

- FSM starts in `IDLE`, waits for power.
- On power-up, initiates SPI communication by entering `MEASUREMENT_MODE`.
- Loops between `SEND` and `RECEIVE` to exchange data.
- On power-off, transitions to `SOFT_RST` to reset communication and return to `IDLE`.
