Name: ru.aurora.geometry_dash_aurora
Summary: Geometry Dash Flutter rhythm platformer for Aurora OS
Version: 1.0.0
Release: 1
License: Proprietary
Source0: %{name}-%{version}.tar.bz2

BuildRequires: cmake
BuildRequires: gcc-c++
BuildRequires: pkgconfig(glib-2.0)
BuildRequires: pkgconfig(gobject-2.0)
BuildRequires: pkgconfig(egl)
BuildRequires: pkgconfig(glesv2)
BuildRequires: pkgconfig(wayland-client)
BuildRequires: pkgconfig(wayland-egl)

%global __provides_exclude_from ^%{_datadir}/%{name}/lib/.*$
%global __requires_exclude ^(libflutter_engine.*|libaurora_embedder.*|libmaliit-glib.*)$

%description
Geometry Dash - динамичный ритм-платформер на Flutter для ОС Аврора.
Чистый Flutter проект без использования QML.

%prep
%autosetup

%build
%cmake -DCMAKE_BUILD_TYPE=Release -DFLUTTER_PROJECT_NAME=%{name}
%make_build

%install
%make_install

%files
%{_bindir}/%{name}
%{_datadir}/%{name}/*
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
