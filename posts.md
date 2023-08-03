---
layout: page
title: Articles
permalink: /articles/
---

<div class="row">
  {% for post in site.posts %}
  <div class="span4" style="margin-bottom: 4px; margin-top: 4px;">
   <div style="display: flex; flex-direction: row; justify-content: space-between;">
    <div>
		<a href="{{ BASE_PATH }}{{ post.url }}"><h3>{{ post.title }}</h3></a>
		{% if post.excerpt %}
		<div>
		{{ post.excerpt | strip_html  }}
		</div>
		{% endif %}
		<a class="btn" href="{{ BASE_PATH }}{{ post.url }}">Read more...</a>
	</div>
	{% if post.thumbnail %}
	<img src="{{ post.thumbnail }}" style="height: 100px" align="center" />
	{% else %}
	<img src="/images/nothumbnail.jpg" style="height: 100px" align="center" />
	{% endif %}
	</div>
  </div>
  <hr/>
  {% endfor %}
</div>