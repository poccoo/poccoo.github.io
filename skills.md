---
layout: page
title: Skills
subtitle: Programming and Statistical Tools
permalink: /skills/
---

<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/devicon.min.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">

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

  .skill-icon-img {
    width: 44px;
    height: 44px;
    margin: 0 auto 10px auto;
    display: block;
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

  .skill-name {
    font-size: 16px;
    font-weight: 600;
    color: #2f2f2f;
  }

  .wetlab-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
    gap: 14px;
    margin-top: 14px;
  }

  .wetlab-card {
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    border: 1px solid #dce3ec;
    border-radius: 10px;
    padding: 11px 12px;
    background: #ffffff;
    min-height: 110px;
  }

  .wetlab-head {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .wetlab-icon {
    width: 20px;
    text-align: center;
    color: #2a6fb0;
    font-size: 14px;
  }

  .wetlab-title {
    font-size: 14px;
    font-weight: 600;
    color: #1f2d3d;
    line-height: 1.25;
  }

  .wetlab-note {
    font-size: 12px;
    color: #5b6773;
    margin-top: 6px;
    line-height: 1.35;
  }
</style>

## Core Tools

<div class="skills-grid">
  <div class="skill-card">
    <img
      class="skill-icon-img"
      src="https://cdn.simpleicons.org/rstudioide/75AADB"
      alt="RStudio icon">
    <div class="skill-name">RStudio</div>
  </div>

  <div class="skill-card">
    <div class="skill-icon">
      <i class="devicon-python-plain colored" aria-hidden="true"></i>
    </div>
    <div class="skill-name">Python</div>
  </div>

  <div class="skill-card">
    <img
      class="skill-icon-img"
      src="https://cdn.simpleicons.org/pytorch/EE4C2C"
      alt="PyTorch icon">
    <div class="skill-name">PyTorch</div>
  </div>

  <div class="skill-card">
    <div class="skill-icon">
      <i class="devicon-mysql-original colored" aria-hidden="true"></i>
    </div>
    <div class="skill-name">MySQL</div>
  </div>

  <div class="skill-card">
    <div class="skill-badge sas" aria-hidden="true">SAS</div>
    <div class="skill-name">SAS</div>
  </div>

  <div class="skill-card">
    <img
      class="skill-icon-img"
      src="https://commons.wikimedia.org/wiki/Special:FilePath/SPSS%20An%20IBM%20Company%20logo.svg"
      alt="SPSS icon">
    <div class="skill-name">SPSS</div>
  </div>

  <div class="skill-card">
    <img
      class="skill-icon-img"
      src="https://cdn.simpleicons.org/cplusplus/00599C"
      alt="C++ icon">
    <div class="skill-name">C++</div>
  </div>
</div>

## Wet-Lab Skills

<div class="wetlab-grid">
  <div class="wetlab-card">
    <div class="wetlab-head">
      <span class="wetlab-icon"><i class="fa-solid fa-flask-vial" aria-hidden="true"></i></span>
      <div class="wetlab-title">Protein Extraction</div>
    </div>
    <div class="wetlab-note">Soy protein protocol optimization.</div>
  </div>

  <div class="wetlab-card">
    <div class="wetlab-head">
      <span class="wetlab-icon"><i class="fa-solid fa-chart-line" aria-hidden="true"></i></span>
      <div class="wetlab-title">IEX-HPLC</div>
    </div>
    <div class="wetlab-note">Comparative protein profiling.</div>
  </div>

  <div class="wetlab-card">
    <div class="wetlab-head">
      <span class="wetlab-icon"><i class="fa-solid fa-vials" aria-hidden="true"></i></span>
      <div class="wetlab-title">Sample Prep</div>
    </div>
    <div class="wetlab-note">Routine prep and lab handling.</div>
  </div>

  <div class="wetlab-card">
    <div class="wetlab-head">
      <span class="wetlab-icon"><i class="fa-solid fa-microscope" aria-hidden="true"></i></span>
      <div class="wetlab-title">Bio/Chem Lab Training</div>
    </div>
    <div class="wetlab-note">Coursework-based lab practice.</div>
  </div>

  <div class="wetlab-card">
    <div class="wetlab-head">
      <span class="wetlab-icon"><i class="fa-solid fa-clipboard-list" aria-hidden="true"></i></span>
      <div class="wetlab-title">Lab Documentation</div>
    </div>
    <div class="wetlab-note">Procedures, outputs, and notes.</div>
  </div>
</div>
