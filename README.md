# Dentaku Zen Garden

## Overview

Dentaku Zen Garden is a sample project demonstrating the use of the Dentaku gem
to allow some business logic to be moved outside of the source code of an
application and safely evaluated at runtime.

The (contrived) scenario is running an ecommerce site to purchase the materials
for enthusiasts to build miniature
[zen gardens](https://en.wikipedia.org/wiki/Japanese_rock_garden) according to
shared plans.  The catch is that the site allows the end user to specify custom
dimensions and then calculates the required materials to construct a garden of
that size.  Additionally, the shipping weight is calculated from the material
quantities and density formulas.

## Setup

To get started, install the dependencies with bundler:

```
bundle install
```

## Usage

To launch the application, execute `app.rb`:

```
bundle exec ruby app.rb
```

And view the application at http://localhost:4567

To configure your own custom zen garden, first choose a plan.  Once a plan is
selected, Dentaku will analyze the material requirements formulas and prompt you
for the custom values required.  After you provide these specific values, the
application displays the required materials and the total calculated shipping
weight.

## Exploring

All the data about projects and materials is stored in the `db` directory.  To
define a new project, create a new CSV file in `db/projects` with one row per
material component of your project.

All of the project calculations are performed in `project.rb`.

The web UI (in Sinatra) is implemented in `app.rb` and the view templates are in
`views`.
