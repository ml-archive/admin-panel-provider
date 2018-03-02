# Admin Panel ✍️
[![Swift Version](https://img.shields.io/badge/Swift-3-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-2-F6CBCA.svg)](http://vapor.codes)
[![Circle CI](https://circleci.com/gh/nodes-vapor/admin-panel-provider/tree/master.svg?style=shield)](https://circleci.com/gh/nodes-vapor/admin-panel-provider)
[![codebeat badge](https://codebeat.co/badges/2aa06de9-5bb5-4c2e-ad1a-ef6e08273184)](https://codebeat.co/projects/github-com-nodes-vapor-admin-panel-provider-master)
[![codecov](https://codecov.io/gh/nodes-vapor/admin-panel-provider/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/admin-panel-provider)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/nodes-vapor/admin-panel-provider)](http://clayallsopp.github.io/readme-score?url=https://github.com/nodes-vapor/admin-panel-provider)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/admin-panel-provider/master/LICENSE)

Admin Panel makes it easy to setup and maintain admin features for your Vapor project. Here's a list of some of the top feautures that comes out of the box with this package:

- **UI Components:** Admin Panel is built using [AdminLTE](https://adminlte.io/), a highly battle-tested and maintained Control Panel Template. This means that you'll have access to features from AdminLTE through [Leaf](https://docs.vapor.codes/2.0/leaf/leaf/#leaf) tags.
- **User System:** This package come with a (admin panel) user system with roles built-in. The package also handles welcome emails and reset-password flows.
- **SSO Support:** Built-in support for adding your own custom SSO provider.
- **Activities**: Need to broadcast certain updates to the admin panel users? No problem, Admin Panel gives you some convenient functionality to manage an activity log.

## 📦 Installation

### Install package using SPM

Update your `Package.swift` file:

```swift
.Package(url: "https://github.com/nodes-vapor/admin-panel-provider.git", majorVersion: 0, minor: 4)
```

Next time you run e.g. `vapor update` Admin Panel will be installed.

### Install resources

Copy the `Resources` and `Public` folders from this repo into your project. You can download the repo as a zip and then move the folders to the root of your project. Remember to check that you're not overwriting any files in your project.


## 🚀 Getting started

### Add provider

In your `Config+Setup.swift` (or wherever you setup your providers), make sure to add the Admin Panel provider:

```swift
import AdminPanelProvider

// ...

private func setupProviders() throws {
    // ...
    try addProvider(AdminPanelProvider.Provider.self)
}
```

Also make sure that you add the Fluent provider if it hasn't been already:

```swift
try addProvider(FluentProvider.Provider.self)
```

### Setup view renderer

This package relies heavily on the [Leaf](https://docs.vapor.codes/2.0/leaf/package/) view renderer. For Admin Panel to work, please make sure that you have added the `LeafProvider`:

```swift
import LeafProvider

// ...

private func setupProviders() throws {
    // ...
    try addProvider(LeafProvider.Provider.self)
}
```

After adding the provider, please make sure that your project is using Leaf as the view renderer. To do that, please ensure that the `view` key is set correctly in `droplet.json`:

```json
"//": "Choose which view renderer to use",
"//": "leaf: Vapor's Leaf renderer",
"view": "leaf"
```

### Seed a user

If you haven't added a SSO provider, the next thing you need to do is to seed a user in order to be able to login into your new admin panel. To do this, first add the seeder command to your `commands` array in your `droplet.json`:

```json
"//": "Choose which commands this application can run",
"//": "prepare: Supplied by the Fluent provider. Prepares the database (configure in fluent.json)",
"commands": [
    "prepare",
    "admin-panel:seeder"
],
```

Next run the seeder by doing:

```
vapor build; vapor run admin-panel:seeder
```

Alternatively, in Xcode, you can edit the `Run` scheme temporarily by adding `admin-panel:seeder` under "Arguments Passed On Launch". This will run the seeder when you run the project. Remember to remove the argument when the user has been seeded.

The user that will be created using the seeder will have the following credentials:

- Email: **admin@admin.com**
- Password: **admin**

### CORS:
It's highly recommended that you add the [CORS middleware](https://docs.vapor.codes/2.0/http/cors/) to your project.

## 🔧 Configurations

Admin Panel can be configured by (adding or) modifying the `adminpanel.json` config file. Below is a breakdown of the available keys.

| Key       | Example value           | Required | Description                              |
| --------- | ----------------------- | -------- | ---------------------------------------- |
| `name`    | `My Tech Blog`          | No       | This will be the title inside of the admin panel. |
| `baseUrl` | `http://mytechblog.com` | No       | This will be used to generate urls for the admin panel (e.g. when resetting a password). |
| `skin`    | `green-light`           | No       | The skin to use for the admin panel. The options will correspond to the [available skins](https://adminlte.io/themes/AdminLTE/documentation/index.html#layout) supported by AdminLTE. Please omit the `skin-` prefix when specifying the skin. |

### Mailgun

To support sending password reset emails, configure Mailgun using `mailgun.json`. In addition to the values for `key` and `domain`, AdminPanelProvider requires a value for the key `fromAddress` and `fromName` which will be used as the sender for password reset emails.

## 🔐 SSO

Single sign-on can be a convenient way to offer users of your project to login into your admin panel. 


## 🏆 Credits

This package is developed and maintained by the Vapor team at [Nodes](https://www.nodesagency.com).
The package owner for this project is [Steffen](https://github.com/steffendsommer).


## 📄 License

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
