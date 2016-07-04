<div class="row">
  <div class="page-header">
    <h3>Search results <small> for "{{:search_term}}"</small></h3>
  </div>
</div>
<div class="row">
  {{#:packages}}
  {{> app/resources/packages/views/package_item.mustache.jl}}
  {{/:packages}}
</div>