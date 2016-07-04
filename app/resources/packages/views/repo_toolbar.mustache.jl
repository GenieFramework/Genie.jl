<div class="btn-group-xs repo-info" role="group">
  <button type="button" class="btn btn-default" title="Forks" data-toggle="tooltip">
    <i class="fa fa-code-fork"></i>
    {{:repo_forks_count}}
  </button>
  <button type="button" class="btn btn-default" title="Stars" data-toggle="tooltip">
    <i class="fa fa-star"></i>
    {{:repo_stargazers_count}}
  </button>
  <button type="button" class="btn btn-default" title="Open issues" data-toggle="tooltip">
    <i class="fa fa-exclamation-triangle"></i>
    {{:repo_open_issues_count}}
  </button>
  {{#:repo_html_url}}
  <button type="link" class="btn btn-default" title="View on GitHub" data-toggle="tooltip">
    <a href="{{:repo_html_url}}" target="_new">
      <i class="fa fa-github"></i>
      {{:name}}
    </a>
  </button>
  {{/:repo_html_url}}
</div>