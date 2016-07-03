<div class="row">
  <div class="jumbotron">
    <h1>Julia Packages</h1>
    <p>The Julia developer community is contributing a number of external packages through Julia’s built-in package manager at a rapid pace</p>
    <p><a class="btn btn-primary btn-lg" href="#" role="button">Learn more</a></p>
  </div>
</div>

<div class="row">
  <div class="col-md-4 section-headers">
    <h4>
      <i class="fa fa-fire"></i>
      Top packages
    </h4>
  </div>
  <div class="col-md-4 section-headers">
    <h4>
      <i class="fa fa-hourglass-start"></i>
      Newest packages
    </h4>
  </div>
  <div class="col-md-4 section-headers">
    <h4>
      <i class="fa fa-refresh"></i>
      Latest updates
    </h4>
  </div>
</div>

<div class="row">
  {{#:packages}}
  <div class="col-md-4 pkg">
    <h4><a href="/packages/{{:id}}">{{:name}}</a></h4>
    <p class="repo-description">
      {{:repo_description}}
    </p>
    <p class="repo-participation" tooltip="{{:repo_participation}}">
      <span class="sparkline" data-points="{{:repo_participation}}" data-preset="hilite-last"></span>
    </p>
    <div class="btn-group-xs repo-info" role="group">
      <button type="button" class="btn btn-default" tooltip="Forks">
        <i class="fa fa-code-fork"></i>
        {{:repo_forks_count}}
      </button>
      <button type="button" class="btn btn-default" tooltip="Stars">
        <i class="fa fa-star"></i>
        {{:repo_stargazers_count}}
      </button>
      <button type="button" class="btn btn-default" tooltip="Watchers">
        <i class="fa fa-eye"></i>
        {{:repo_watchers_count}}
      </button>
      <button type="button" class="btn btn-default" tooltip="Open issues">
        <i class="fa fa-exclamation-triangle"></i>
        {{:repo_open_issues_count}}
      </button>
      <button type="link" class="btn btn-default" tooltip="View on GitHub">
        <a href="{{:url}}" target="_new">
          <i class="fa fa-github"></i>
          {{:name}}
        </a>
      </button>
    </div>
  </div>
  {{/:packages}}
</div>