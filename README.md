
<br />
<p align="center">

  <h3 align="center">Vulnerable Django App | Immunity instrumented</h3>

  <p align="center">
    An example of an extremely vulnerable Django application.
    <br />
    <br />
    ·
    <a href="https://github.com/lambrou/vulnerable-django-app/issues">Report Bug</a>
    ·
    <a href="https://github.com/lambrou/vulnerable-django-app/issues">Request Feature</a>
  </p>
</p>

<hr/>
<h3 align="center">Разметка уязвимостей</h3>


| Файл                    | Строка | Уязвимость               | CWE-метка для датасета  |
|-------------------------|--------|--------------------------|-------------------------|
| /app/core/views.py      | 40     | Command execution        | CWE-77                  |
| /app/core/views.py      | 69     | Command execution        | CWE-77                  |
| /app/core/views.py      | 50     | CSRF                     | CWE-352                 |
| /app/core/views.py      | 90     | SQLi                     | CWE-89                  |
| /app/core/views.py      | 24     | Configuration (hardcode) | CWE-16                  |
| /app/core/views.py      | 101    | XSS                      | CWE-79                  |


<hr/>

<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Contributing](#contributing)
* [License](#license)
* [Acknowledgements](#acknowledgements)



<!-- ABOUT THE PROJECT -->
## About The Project

![vulnerable-django-app](vda/core/static/core/vdss.png)

### Built With

* [Python 3.8.2](https://www.python.org/downloads/)
* [Django 3.0.5](https://www.djangoproject.com/)



<!-- GETTING STARTED -->
## Getting Started

Currently only tested and supported on Windows.

### Prerequisites

* Django
```sh
pip install django
```

### Installation

1. Clone the repo
```sh
git clone https://github.com/lambrou/vulnerable-django-app.git
```
2. Run the server
```sh
python manage.py runserver 0.0.0.0:8085
```
If you want to access the server from another machine (not on LAN), you will need to forward port 8085 (or whatever port you wish to use) from your router.




<!-- CONTRIBUTING -->
## Contributing

Contributions are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.




<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements

* [othneildrew](https://github.com/othneildrew/Best-README-Template) - For this wonderful README template.