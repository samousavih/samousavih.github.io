---
layout: page
title: 
permalink: /
---
<div class="container">
  <div class="profile-image">
    <img src="/images/profile.jpg" alt="Profile photo of Amin Mousavi" />
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
        <a href="/articles">See more posts ...</a>
    </div>
    <div>
      <header class="post-header">
        <h2 class="post-title">Talks</h2>
      </header>  
      <div class="post-content">
        <p>Occasionally I speak at meetups and conferences. </p>
        <p>
         <div class="row">
          <div style="margin-top: 10px;">
            <a href="https://youtu.be/nz6cSJV1XQk">Partial Function Application in Python: A look under the hood of popular Python repositories on GitHub</a>
            <h5>DDD Melbourne: January 2025</h5>
          </div>
          <div style="margin-top: 10px;">
            <a href="https://www.meetup.com/akl-net/events/294755381/">Linqing Railways: How to make Functional Code in C# more Readable and Flexible</a>
            <h5>Auckland .NET User Group: July 2023</h5>
          </div>
          <div style="margin-top: 10px;">
            <a href="https://www.meetup.com/brisjs/events/qswzrkywlbkb/">Scaffolding JS stacks using Yeoman, Cloud 66, Docker and push it to Cloud</a>
            <h5>BrisJs: Aug 2017</h5>
          </div>
        </div>
        </p>
    </div>
  </div>
</div>
