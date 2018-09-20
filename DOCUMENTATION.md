
Decidim - Questions module
===

> based on decidim-proposals#0.12.1

The global idea is the transform the proposals module into a question & answer module. Most of the features are already available in the proposals module like answer and internal discussion management.

_In this document, the `Proposal` object become a `Question`_

We add 2 new roles (Service and Committee) and some UX enhancements based on the later to manage to workflow of questions : changing state, forwarding answer, notifying users involved.

### Add
- **New participatory process roles : Service & Committee**  
- **"Type" field on the `Question object**  
use the defined the type of question :
  - question
  - opinion
  - contribution  
- **line**  
description

### Changes
#### User side
- **Not answered `Questions` are not shown in the user list**  
- **:children_crossing: publish --> need moderation**  
  - disable general notification for process followers
  - notification for moderation for moderators only
  - notification / confirmation to author

#### Admin side
- **`Questions` are grouped by state in separated table list**  
each table as its own set of available actions
- **Permissions on admin actions**
_TO BE LISTED_
- **`Question` body can be edited by _admin_ roles**
And the original body is backed up in the dedicated field
- **Answer body only available when rejecting a `Question`**
