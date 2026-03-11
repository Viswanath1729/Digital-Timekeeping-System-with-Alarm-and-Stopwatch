# Digital Timekeeping System with Alarm and Stopwatch

## Overview

This project implements a multi-mode digital clock system using Verilog HDL on an FPGA platform. The design is targeted for the Digilent Basys-3 FPGA board and utilizes the onboard 100 MHz clock to generate precise timing signals for both real-time clock and stopwatch functionality.

The system supports multiple operating modes including normal clock display, time adjustment, and stopwatch operation. User interaction is performed through the onboard push buttons and switches, while output is displayed on the four-digit seven-segment display using time-multiplexing techniques.

## Features

* Real-time digital clock implementation
* Integrated stopwatch functionality
* Multiple display modes (Clock / Stopwatch)
* Button-based time adjustment
* Seven-segment display multiplexing
* Modular Verilog design architecture

## Hardware Used

* Digilent Basys-3 FPGA Board
* 100 MHz onboard clock
* Push buttons for control inputs
* Slide switches for mode selection
* 4-digit seven-segment display

## Development Tools

* Xilinx Vivado Design Suite
* Verilog Hardware Description Language

## Design Concepts Demonstrated

* Clock division from high-frequency system clock
* Synchronous counters for time tracking
* Mode control logic using conditional design
* Hardware display multiplexing
* Modular digital system design

## Project Structure

```
project/
│
├── src/
│   └── digital_clock_advanced.v
│
├── constraints/
│   └── basys3.xdc
│
└── README.md
```

## Implementation Steps

1. Create a new project in Vivado.
2. Add the Verilog source files from the `src` directory.
3. Add the Basys-3 constraint file (`.xdc`).
4. Run synthesis and implementation.
5. Generate the bitstream.
6. Program the FPGA board.

## Learning Outcomes

* Practical experience with FPGA-based system design
* Understanding of clock management in hardware
* Implementation of modular Verilog designs
* FPGA synthesis and deployment workflow
