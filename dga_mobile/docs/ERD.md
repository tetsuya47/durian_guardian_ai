# Entity Relationship Diagram (ERD)

This document shows document relationships mapped inside MongoDB.

```
  ┌──────────────┐
  │    farms     │◄────────────┐
  └──────┬───────┘             │
         │ 1                   │
         │                     │
         │ N                   │
  ┌──────▼───────┐             │
  │    zones     │             │
  └──────┬───────┘             │
         │ 1                   │
         │                     │
         │ N                   │
  ┌──────▼───────┐             │
  │    trees     │             │
  └──────┬───────┘             │
         │ 1                   │
         ├─────────────────────┼─────────────┐
         │ N                   │ 1           │ 1
  ┌──────▼───────┐     ┌───────┴──────┐     ┌▼─────────────┐
  │disease_history│     │    alerts    │     │ inspections  │
  └──────────────┘     └──────────────┘     └──────────────┘
```
