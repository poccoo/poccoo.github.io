---
layout: page
title: Skills
subtitle: Programming and Statistical Tools
permalink: /skills/
---

<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/devicon.min.css">

<style>
  .skills-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
    gap: 16px;
    margin-top: 18px;
  }

  .skill-card {
    border: 1px solid #d9d9d9;
    border-radius: 12px;
    padding: 18px 12px;
    background: linear-gradient(160deg, #ffffff 0%, #f4f7fb 100%);
    text-align: center;
    transition: transform 0.18s ease, box-shadow 0.18s ease;
  }

  .skill-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1);
  }

  .skill-icon {
    font-size: 44px;
    line-height: 1;
    margin-bottom: 10px;
  }

  .skill-badge {
    width: 44px;
    height: 44px;
    margin: 0 auto 10px auto;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    font-weight: 700;
    color: #ffffff;
    letter-spacing: 0.4px;
  }

  .skill-badge.sas {
    background: #00539b;
  }

  .skill-badge.spss {
    background: #0f62fe;
  }

  .skill-name {
    font-size: 16px;
    font-weight: 600;
    color: #2f2f2f;
  }
</style>

## Core Tools

<div class="skills-grid">
  <div class="skill-card">
    <div class="skill-icon">
      <i class="devicon-r-original colored" aria-hidden="true"></i>
    </div>
    <div class="skill-name">R</div>
  </div>

  <div class="skill-card">
    <div class="skill-icon">
      <i class="devicon-python-plain colored" aria-hidden="true"></i>
    </div>
    <div class="skill-name">Python</div>
  </div>

  <div class="skill-card">
    <div class="skill-badge sas" aria-hidden="true">SAS</div>
    <div class="skill-name">SAS</div>
  </div>

  <div class="skill-card">
    <div class="skill-badge spss" aria-hidden="true">SPSS</div>
    <div class="skill-name">SPSS</div>
  </div>
</div>
