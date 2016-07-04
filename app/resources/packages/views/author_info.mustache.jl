<div class="btn-group-ms author-info" role="group">
  <a class="btn btn-link" title="Author {{:author_fullname}} {{:author_company}}" href="{{:author_html_url}}" data-toggle="tooltip" data-placement="right">
    <i class="fa fa-user"></i>
    {{:author_name}} 
  </a>
  {{#:author_followers_count}}
  <span class="badge" title="Followers" data-toggle="tooltip">
    <i class="fa fa-binoculars"></i>
    {{:author_followers_count}}
  </span>
  {{/:author_followers_count}}
</div>