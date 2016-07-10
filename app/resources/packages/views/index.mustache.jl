{{> app/resources/packages/views/jumbotron.mustache.jl}}

{{:fts}}

<div class="row">
  <div class="col-md-4 section-headers">
    <h4>
      <i class="fa fa-fire"></i>
      Top packages
    </h4>
    {{#:top_packages_data}}
    {{> app/resources/packages/views/package_item.mustache.jl}}
    {{/:top_packages_data}}
  </div>

  <div class="col-md-4 section-headers">
    <h4>
      <i class="fa fa-hourglass-start"></i>
      Newest
    </h4>
    {{#:new_packages_data}}
    {{> app/resources/packages/views/package_item.mustache.jl}}
    {{/:new_packages_data}}
  </div>

  <div class="col-md-4 section-headers">
    <h4>
      <i class="fa fa-refresh"></i>
      Latest updates
    </h4>
    {{#:updated_packages_data}}
    {{> app/resources/packages/views/package_item.mustache.jl}}
    {{/:updated_packages_data}}
  </div>
</div>