---
layout: page
title: Articles
permalink: /articles/
---

<div class="row">
  {% for post in site.posts %}
  <div class="span4">
    <a href="{{ BASE_PATH }}{{ post.url }}"><h2>{{ post.title }}</h2></a>
	<p>{% if post.thumbnail %}
	<img src="{{ post.thumbnail }}" style="height: 280px" align="center" />
	{% else %}
	<img src="/images/nothumbnail.jpg"
  style="height: 280px" align="center" />
	{% endif %}
	</p>
	{% if post.excerpt %}
	<p>
	{{ post.excerpt | strip_html  }}
	</p>
	{% endif %}
	<p>
	<a class="btn" href="{{ BASE_PATH }}{{ post.url }}">Read more...</a>
	</p>
  </div>
  {% endfor %}
</div>