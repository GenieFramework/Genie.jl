<div class="pkg">
  {{> app/resources/packages/views/package_item_heading.mustache.jl}}
  {{> app/resources/packages/views/author_info.mustache.jl}}      
  
  <p class="repo-description">
    {{:repo_description}}
    {{#:search_headline}}
    <blockquote class="search_headline">
      <p>
        {{{:search_headline}}}
      </p>
    </blockquote>
    {{/:search_headline}}
  </p>

  {{> app/resources/packages/views/package_item_participation.mustache.jl}}
  {{> app/resources/packages/views/repo_toolbar.mustache.jl}}

  {{#:repo_readme}}
  <br/>
  <hr/>
  <p class="text-center">GitHub README</p>
  <hr/>
  <p class="repo-readme">
    {{{:repo_readme}}}
  </p>
  {{/:repo_readme}}
</div>