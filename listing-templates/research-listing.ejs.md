<%
// Based on Quarto's own listing-default.ejs.md / item-default.ejs.md
// (see /Applications/quarto/share/projects/website/listing/), extended with
// one thing the built-in template can't do: a PDF pill on the listing itself,
// driven by an optional `pdf:` field in each page's front matter. Reuses the
// existing .paper-links pill CSS from theme.scss instead of inventing new
// classes. See CLAUDE.md for when/why this exists.
//
// IMPORTANT: setting `template:` on a listing makes Quarto treat it as
// listing.type "custom" internally (see quarto.js paramsForType), which gets
// a DIFFERENT ejs param shape than the built-in default/grid/table types:
// no `listing` object at all, just `items`, a flat `metadataAttrs(item)`
// function, and `templateParams`. Do not reference `listing.*` here.
//
// Quarto also evaluates this template in a dependency-scanning pass that
// does not bind these params at all — bail out cleanly in that case.
const hasContext = typeof items !== 'undefined';
const attrsFor = (hasContext && typeof metadataAttrs === 'function')
  ? metadataAttrs
  : () => '';
%>
<% if (hasContext) { %>

::: {.list .quarto-listing-default}

<% for (const item of items) { %>

::: {.quarto-post .image-left <%= attrsFor(item) %>}
::: {.body}

<h3 class="no-anchor listing-title"><a href="<%- item.path %>" class="no-external"><%= item.title %></a></h3>
<% if (item.subtitle) { %>
<div class="listing-subtitle"><a href="<%- item.path %>" class="no-external"><%= item.subtitle %></a></div>
<% } %>

<% if (item.description) { %>

```{=html}
<div class="delink listing-description"><a href="<%- item.path %>" class="no-external">
```

<%= item.description %>

```{=html}
</a></div>
```

<% } %>

<% if (item.pdf) { %>

::: {.paper-links .listing-pdf-link}
- [PDF](<%- item.pdf %>)
:::

<% } %>

:::
:::

<% } %>

:::

<% } %>
