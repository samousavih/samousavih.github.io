---
layout: page
title: 
permalink: /
---
<div class="container">
  <div class="profile-image">
    <img src="/images/profile.jpg"  />
  </div>
  <div class="profile-details">
    <div>
      <header class="post-header">
        <h2 class="post-title">About me</h2>
      </header>  
      <div class="post-content">
        <p>I am a software engineer and technical leader.</p>
        <a href="/about"> More about me ...</a>
      </div>
    </div>
    <div>
      <header class="post-header">
        <h2 class="post-title">My writings</h2>
      </header>  
      <div class="post-content">
        <p>I write about a variety of topics, whatever tickles my curiosity. Most of my writings are to explain software engineerings concepts deeper. </p>
        <p>
         <div class="row">
          {% for post in site.posts limit:4 %}
          <div style="margin-top: 10px;">
            <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a>
          </div>
          {% endfor %}
        </div>
        </p>
        <a href="/posts">See more posts ...</a>
    </div>
  </div>
</div>
