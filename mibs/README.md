# Custom SNMP MIBs Directory

This directory can be used to add custom SNMP MIBs to the Zabbix Proxy container.

## Usage

MIB files are managed in two ways:
1. **Automatically downloaded MIBs**: MIBs listed in `mibs.json` are automatically downloaded by a GitHub Action
2. **Manually added MIBs**: You can place your custom MIB files directly in this directory

All MIB files will be copied to `/usr/share/snmp/mibs/custom` inside the container during build.

## Adding New MIBs via GitHub

To add a new MIB for automatic downloading:

1. Create a pull request using the "Add SNMP MIB" template
2. Fill in the required information, including the MIB name and URL
3. Submit the pull request

The GitHub Action will automatically download the MIB when the PR is merged.

## Requirements

- MIB files should be in standard SNMP MIB format
- File names should typically end with `.txt` or have no extension
- Avoid having spaces or special characters in the file names

## Benefits

- Custom MIBs will be available to all SNMP tools in the container
- No need to modify the container after deployment
- Clean separation between standard and custom MIBs

## Example

If you have a custom MIB file called `MY-CUSTOM-MIB.txt`, place it in this directory and it will be available in the container at `/usr/share/snmp/mibs/custom/MY-CUSTOM-MIB.txt`.

## Testing

You can test that your custom MIB is being properly loaded using:

```bash
snmptranslate -IR -Td MY-CUSTOM-MIB::objectName
```

## Troubleshooting

If your MIB isn't being recognized, check:

1. The MIB format is valid (syntax errors will prevent loading)
2. Any dependent MIBs are also present
3. File permissions are correct (should be readable)
4. The container has been rebuilt after adding the MIB files

## Automated MIB Management

This project includes an automated MIB management system that:

1. **Downloads MIBs**: A GitHub Action automatically downloads MIBs from specified URLs
2. **Tracks Changes**: SHA256 checksums are used to detect changes in MIB files
3. **Updates Documentation**: A summary of available MIBs is maintained in `SUMMARY.md`

### The `mibs.json` File

MIB sources are defined in the `mibs.json` file with the following structure:

```json
{
  "mibs": [
    {
      "name": "example-mib",
      "url": "https://example.com/path/to/example-mib.txt",
      "description": "Example MIB for Device XYZ",
      "version": "1.0.0",
      "last_updated": "2025-06-24"
    }
  ]
}
```

### GitHub Action Workflow

The `download-mibs.yml` workflow:
- Runs weekly and on changes to `mibs.json`
- Downloads all MIBs defined in the configuration
- Updates the `last_updated` field when changes are detected
- Creates SHA256 checksums for change detection
- Commits changes back to the repository

You can also manually trigger the workflow from the Actions tab in GitHub.
