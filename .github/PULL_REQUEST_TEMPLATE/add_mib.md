---
name: Add SNMP MIB
about: Add a new SNMP MIB for inclusion in the container builds
title: 'feat(mib): add [MIB NAME] MIB'
labels: 'enhancement, mibs'
assignees: ''
---

## MIB Details

<!--
Please provide the following information for the MIB you want to add:
- name: A short name for the MIB file (no spaces or special characters)
- url: The URL where the MIB file can be downloaded (MUST be freely accessible)
- description: A brief description of what this MIB is for
- version: The version of the MIB (if known)

NOTE: Only MIBs that are freely available for download will be accepted.
-->

```json
{
  "name": "example-mib",
  "url": "https://example.com/path/to/example-mib.txt",
  "description": "Example MIB for Device XYZ",
  "version": "1.0.0"
}
```

## Vendor Information

<!--
Please provide information about the vendor/manufacturer who created this MIB:
- Vendor name
- Product line
- Documentation link (if available)
-->

**Vendor:**
**Product Line:**
**Documentation Link:**

## Testing

<!--
Have you tested the MIB? Please describe any testing you have done:
- Have you verified the MIB loads correctly?
- Have you tested it with actual devices?
-->

## Additional Information

<!--
Any additional information that may be helpful
-->

## Legal Disclaimer

<!--
Please acknowledge the following disclaimer:
-->

> **Note:** The maintainers of this repository are not responsible for the accuracy, functionality, or licensing of the MIBs provided. By submitting this MIB, you confirm that it is freely available for download and that its inclusion does not violate any copyright or licensing restrictions. Users are responsible for ensuring proper usage rights for any MIBs they implement.

## Checklist
- [ ] I have verified the MIB URL is publicly accessible
- [ ] I have checked that the MIB is not already included in the repository
- [ ] I have verified the MIB is in standard SNMP MIB format
- [ ] I have provided all required information in the JSON format above
- [ ] I confirm the MIB is free to download without licensing restrictions
- [ ] I understand that the repository maintainers are not responsible for the accuracy or licensing of the MIB
