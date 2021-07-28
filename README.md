# NavigationTitleContextView
A custom UIView that resides within a navigation bar that has a control for accessing a context menu.

## Status
This project is currently a work-in-progress.

## Intent
The intent of this view is to provide a way to inject a custom navigation view that allows for subtle, custom messaging that often can be displayed as a banner, notification, or alert. The user experience mimics that of adding a prompt to a navigation item, but is displayed underneath the navigation title.

Additionally, this view allows for hooking into a tappable area within the navigation view. The idea for this tappable area is to provide some kind of hook into a context menu. This is optional and can be omitted by modifying the configuration of the context view.
