---
type: reference
---
## Email
Email bits.

### Email DMARC
[DMARC](https://dmarc.org/) is an open email Internet standard detailed in [RFC 7489](https://datatracker.ietf.org/doc/html/rfc7489). 

Domain-based Message Authentication, Reporting, and Conformance (DMARC) works with Sender Policy Framework (SPF) and DomainKeys Identified Mail (DKIM) to authenticate mail senders. Together they help destination email systems trust messages sent from your domain. Implementing DMARC with SPF and DKIM provides additional protection against spoofing and phishing email. DMARC helps receiving mail systems determine what to do with messages sent from your domain that fail SPF or DKIM checks.

- Sample DNS TXT record DMARC setup: 

  ```
  dig txt _dmarc.mydomain.com +short
  "v=DMARC1; p=reject; pct=100; rua=mailto:dmarc@mydomain.com"
  ```

- Microsoft has a good write-up here <https://learn.microsoft.com/en-us/defender-office-365/email-authentication-dmarc-configure?view=o365-worldwide>

- Prajit Sindhkar also has another good write-up here <https://medium.com/techiepedia/how-to-report-dmarc-vulnerabilities-efficiently-to-earn-bounties-easily-f7a65ecdd20b>

- ProtonMail has yet another good post here <https://proton.me/support/anti-spoofing-custom-domain>

