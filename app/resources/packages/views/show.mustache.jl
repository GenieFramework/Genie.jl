<div class="container">
  <br/><br/>
  <div class="row">
    {{#:packages}}
    {{> app/resources/packages/views/package_item.mustache.jl}}
    {{/:packages}}
  </div>
</div>