# Ash Framework Documentation

Welcome to the Ash Framework documentation! Here you will find everything you need to know to get started with and use Ash.

## Dive In

- [What is Ash?](documentation/topics/about_ash/what-is-ash.md)
- [Get Started](documentation/tutorials/get-started.md)

## About the Documentation

[**Tutorials**](#tutorials) walk you through a series of steps to accomplish a goal. These are **learning-oriented**, and are a great place for beginners to start.

---

[**Topics**](#topics) provide a high level overview of a specific concept or feature. These are **understanding-oriented**, and are perfect for discovering design patterns, features, and tools related to a given topic.

---

[**How-to**](#how_to) guides are **goal-oriented** recipes for accomplishing specific tasks. These are also good to browse to get an idea of how Ash works and what is possible with it.

---

**Reference** documentation is produced automatically from our source code. It comes in the form of module documentation and DSL documentation. This documentation is **information-oriented**. Use the sidebar and the searchbar to find relevant reference information.

## Tutorials

- [Get Started](documentation/tutorials/get-started.md)

---

## Topics

### Resources

- [Attributes](documentation/topics/resources/attributes.md)
- [Calculations](documentation/topics/resources/calculations.md)
- [Aggregates](documentation/topics/resources/aggregates.md)
- [Code Interfaces](documentation/topics/resources/code-interfaces.md)

### Actions

- [Actions](documentation/topics/actions/actions.md)
- [Read Actions](documentation/topics/actions/read-actions.md)
- [Create Actions](documentation/topics/actions/create-actions.md)
- [Update Actions](documentation/topics/actions/update-actions.md)
- [Destroy Actions](documentation/topics/actions/destroy-actions.md)
- [Generic Actions](documentation/topics/actions/generic-actions.md)
- [Manual Actions](documentation/topics/actions/manual-actions.md)

### Security

- [Actors & Authorization](documentation/topics/security/actors-and-authorization.md)
- [Sensitive Data](documentation/topics/security/sensitive-data.md)
- [Policies](documentation/topics/security/policies.md)

### Development

- [Development Utilities](documentation/topics/development/development-utilities.md)
- [Upgrading to 3.0](documentation/topics/development/upgrading-to-3.0.md)

### About Ash

- [What is Ash?](documentation/topics/about_ash/what-is-ash.md)
- [Our Design Principles](documentation/topics/about_ash/design-principles.md)
- [Contributing to Ash](documentation/topics/about_ash/contributing-to-ash.md)

---

## How To

---

## Reference

- [Glossary](documentation/topics/reference/glossary.md)

## Packages

The Ash ecosystem consists of numerous packages, all of which have their own documentation. If you can't find something in this documentation, don't forget to search in any potentially relevant package.

### Data Layers

- [AshPostgres](https://hexdocs.pm/ash_postgres) | PostgreSQL data layer
- [AshSqlite](https://hexdocs.pm/ash_sqlite) | SQLite data layer
- [AshCsv](https://hexdocs.pm/ash_csv) | CSV data layer
- [AshCubdb](https://hexdocs.pm/ash_cubdb) | CubDB data layer

### API Extensions

- [AshJsonApi](https://hexdocs.pm/ash_json_api) | JSON:API builder
- [AshGraphql](https://hexdocs.pm/ash_graphql) | GraphQL builder

### Web

- [AshPhoenix](https://hexdocs.pm/ash_phoenix) | Phoenix integrations
- [AshAuthentication](https://hexdocs.pm/ash_authentication) | Authenticate users with password, OAuth, and more
- [AshAuthenticationPhoenix](https://hexdocs.pm/ash_authentication_phoenix) | Integrations for AshAuthentication and Phoenix

### Finance

- [AshMoney](https://hexdocs.pm/ash_money) | A money data type for Ash
- [AshDoubleEntry](https://hexdocs.pm/ash_double_entry) | A double entry system backed by Ash Resources

### Resource Utilities

- [AshOban](https://hexdocs.pm/ash_oban) | Background jobs and scheduled jobs for Ash, backed by Oban
- [AshArchival](https://hexdocs.pm/ash_archival) | Archive resources instead of deleting them
- [AshStateMachine](https://hexdocs.pm/ash_state_machine) | Create state machines for resources
- [AshPaperTrail](https://hexdocs.pm/ash_paper_trail) | Keep a history of changes to resources

### Admin & Monitoring

- [AshAdmin](https://hexdocs.pm/ash_admin) | A push-button admin interface
- [AshAppsignal](https://hexdocs.pm/ash_appsignal) | Monitor your Ash resources with AppSignal

### Testing

- [Smokestack](https://hexdocs.pm/smokestack) | Declarative test factories for Ash resources