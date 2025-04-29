# Wonder Resources Contract

A Clarity-based smart contract to register, manage, and control access to a structured collection of digital resources. Each item includes metadata such as name, dimensions, context, and categorized tags, with a robust permission system ensuring only authorized access.

---

## 🚀 Features

- 📦 **Item Registry**: Add, modify, or remove uniquely identified collection items.
- 🧾 **Metadata Handling**: Each item contains name, author, dimensions, context, and up to 10 category tags.
- 🔐 **Permission System**: Author-controlled viewer access using principal-based rights.
- ✍️ **Authorship Control**: Reassign or validate item ownership.
- 📊 **System Counters**: Auto-incrementing item identifiers with state tracking.

---

## 📜 Contract Functions

### Public Functions

- `register-collection-item`: Add a new item with metadata and categories.
- `retrieve-item-context`: Fetch context string of an item.
- `verify-viewer-access`: Check viewer's access permission.
- `count-item-categories`: Count tags for a specific item.
- `verify-name-compliance`: Check item name formatting.
- `reassign-item-ownership`: Transfer item authorship.
- `modify-item-details`: Edit existing item metadata.
- `purge-collection-item`: Delete item from the collection.

### Private Functions

- Validations for string length, category descriptors, author identity, etc.
- Collection state management (counter, permission mapping).

---

## 🛠 Development

This contract is written in **Clarity**, a smart contract language for the **Stacks blockchain**.

### Requirements

- [Clarinet](https://github.com/hirosystems/clarinet) for development and testing.

### Setup

```bash
git clone https://github.com/your-username/wonder-resources-contract.git
cd wonder-resources-contract
clarinet check
