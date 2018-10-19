# Consular Cards

An application for browsing the Consular Cards, a set of ~6,500 index cards that were used internally by the U.S. Department of State to track the staff of U.S. diplomatic posts abroad. The cards have been scanned and minimally indexed and reviewed by the Office of the Historian. The application provides a searchable list of the cards by label and some basic metadata about each scan. The images have not been fully transscribed, but the goal is to create a usable resource until such time as the cards can be transcribed and further enriched.

## Dependencies

- The data in the `data` collection is TEI XML
- The application runs in [eXist-db](https://exist-db.org).
- Building the installable package requires Apache Ant

## Installation

- Check out the repository
- Run `ant`
- Upload build/consular-cards-0.1.0.xar to eXist-db's Dashboard > Package Manager
- Open http://localhost:8080/exist/apps/consular-cards
- 