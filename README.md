# Promiscuous::BlackHole

> *black hole* (noun): a region of space having a gravitational field so intense that no matter or
> radiation can escape.

At Crowdtap, we love working with [promiscuous](https://github.com/promiscuous-io/promiscuous).
It makes it really cheap to break out microservices, which keeps apps small lean and agile.
Unfortunately, since each of those small apps stores data independently, it's hard to pull all that data
back together for analysis. That's where Promiscuous::BlackHole comes in.

Promiscuous::BlackHole hooks into existing data streams, automatically
extracts all published data, and stores that data in a postgres database.

Usage
--------------------
### 1. Install and use promiscuous
Promiscuous::BlackHole depends on a working version of promiscuous.

### 2. Connect to your existing promiscuous subscribers
 - Configure Promiscuous as normal to connect to publishers
 - Configure Promiscuous::BlackHole to specify the database connection

### 3. From the console, run `Promiscuous::BlackHole.start`

Roadmap / Limitations
--------------------
1. Extend support for subscribing to ids that are not bson ids
2. Create adapter framework for supporting data stores other than postgres
3. Add configuration options
   - date and datetime regex
   - version field (use from Promiscuous)
   - type field
4. Add CLI
