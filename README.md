# Dell Fan Control
This simple script is used to manually control the fan speeds on Dell servers using IPMI (Intelligent Platform Management Interface).

## Requirements

- PowerShell
- Internet connection (for initial download of `ipmitool` if not already installed)
- Tested on:
  - Dell T620
  - Dell R730XD
  - Dell R630
- **Your server MUST support IPMI in order for this script to work**

## Installation and Configuration

1. **Download and Install IPMI Tool**: The script will automatically download and install `ipmitool` if it is not found in the expected directory.
2. **Create IPMI Configuration**: If the configuration file does not exist, the script will prompt you to enter the IPMI login credentials and IP address. This information will be saved in a configuration file for future use.

## Usage

1. **Run the Script**: Execute the script in PowerShell.
2. **Load Configuration**: The script will load the IPMI configuration from the file or prompt for details if not already configured.
3. **Check Server Reachability**: The script tests if the IPMI server is reachable.
4. **Validate Credentials**: The script verifies the IPMI credentials and ensures that IPMI is enabled on the server.
5. **Display Current Fan Speeds**: The script retrieves and displays the current fan speeds of the server.
6. **Manual Fan Control**: 
   - If you choose to manually control the fans, you can enter the desired fan speed percentage.
   - The script converts the fan speed to hexadecimal and sets the fan speed.
   - If you opt not to manually control the fans, the script will exit.

## Notes

- Ensure IPMI is enabled on the server by navigating to the IDRAC web interface, going to IDRAC settings, and enabling IPMI over LAN.
- The script prompts for IPMI login details only once and stores them in a configuration file for future use.
- It is recommended to run the script with appropriate administrative privileges to ensure all commands execute successfully.