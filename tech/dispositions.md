---
type: reference
---
## Dispositions

A disposition is the recorded decision about how a finding, issue, or defect was handled. The word turns up in audit, compliance, quality assurance, security, and any [issue tracker](https://en.wikipedia.org/wiki/Issue_tracking_system). A finding that has been dispositioned has had three things happen to it. Someone decided what to do. The decision was written down. The item left the open pile.

None of that means it was fixed. "Dispositioned" and "fixed" are different claims, and a report that blurs them hides risk.

### Common labels

| Label | What it means | Fixed? |
|---|---|---|
| Remediated | The problem was corrected and checked. | Yes |
| Accepted | The finding is valid and someone owns it. | Not yet |
| Deferred | It is valid, and the work is put off to a named later time. | No |
| Risk accepted | It is valid, and the owner chose to [live with it](https://en.wikipedia.org/wiki/Risk_management#Risk_retention), often until a set date. | No |
| Won't fix | It is valid, and nobody will act on it. | No |
| False positive | The tool or reviewer was [mistaken](https://en.wikipedia.org/wiki/False_positives_and_false_negatives). There was nothing to fix. | Nothing to fix |
| Duplicate | The same finding is already tracked elsewhere. | See the other item |
| Not applicable | The rule does not apply to this system or case. | Nothing to fix |

### How three real tools say it

| Tool | Its word for it | Labels it ships |
|---|---|---|
| [Jira](https://support.atlassian.com/jira-cloud-administration/docs/what-are-issue-statuses-priorities-and-resolutions/) | Resolution | Done, Won't do, Duplicate, Cannot reproduce |
| [SonarQube](https://docs.sonarsource.com/sonarqube-server/user-guide/issues/managing) | Status | Accepted, False positive |
| [DefectDojo](https://docs.defectdojo.com/triage_findings/findings_workflows/finding_status_definitions/) | Status | False positive, Out of scope, Risk accepted |

Jira's "Won't do" is defined as "This work item won't be actioned." DefectDojo's "Risk accepted" lasts only "until the Risk Acceptance expires."

### Reading a report

- Ask for the count by label, not the count of closed items.
- Treat "risk accepted" and "deferred" as open risk with a date on it.
- Check who may set "false positive". It is the easiest label to abuse.

This site dispositions its own raw ideas the same way. Each one ends as Publish, Merge, Park, or Drop, and the decision is logged.
