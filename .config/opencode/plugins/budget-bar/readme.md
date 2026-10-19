# budget-bar

Appends OpenCode Go plan usage to the prompt footer, one entry per window, for example `5h 2% (4h26m) wk 69% (2d4h) mo 83% (16d4h)`, where the percentage is the share of that window's allowance consumed and the value in parentheses is the time remaining until the window resets.

On first run the plugin prompts for an OpenCode Console service account key (`oc_sk_...`) with All permission, because the Console offers nothing narrower for usage reads, and stores it for later launches; the segment hides itself whenever data is unavailable, and submitting an empty value clears the stored key.

Adds a `/budget-bar-key` command to replace or clear the service account key at any time. To rotate the key, revoke it in the Console and paste the replacement with the same command.

