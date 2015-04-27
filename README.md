[![Test Coverage](https://codeclimate.com/github/Elyasin/Come-Malaka-Expenses/badges/coverage.svg)](https://codeclimate.com/github/Elyasin/Come-Malaka-Expenses) [![Code Climate](https://codeclimate.com/github/Elyasin/Come-Malaka-Expenses/badges/gpa.svg)](https://codeclimate.com/github/Elyasin/Come-Malaka-Expenses) [![Build Status](https://travis-ci.org/Elyasin/Come-Malaka-Expenses.svg?branch=master)](https://travis-ci.org/Elyasin/Come-Malaka-Expenses) [![security](https://hakiri.io/github/Elyasin/Come-Malaka-Expenses/master.svg)](https://hakiri.io/github/Elyasin/Come-Malaka-Expenses/master)

# README

**This app is still in beta. Feel free to feed back or to join.**

## ToDos:

 * Layout devise error messages

 * Web/Mail Design/Sitemap/Navigation - Foundation/Responsive

 * Use Charts to display data (e.g. Who owes you?)

 * Implement auto-complete when inviting user/participant

 * DRY out the code: partials, (mail) view helpers, JavaScript, etc.

 * Refactor:
 		Value objects, Service objects, Form objects, Query objects, View objects, Policy objects, Decorators...

 * Tests: Integration Tests, Helper Tests
 		Tigthen/Straighten tests: Use strings instead of helpers, use "assigns(...)" instead of instance variables, ...

 * Look into CI for HTML/JavaScript: Selenium/PhantomJS, SauceLab, .... ?

 * Soft delete a user (Mongoid Paranoid)

 * Notification stream for user

 * Search engine for events/items

 * User can type in base amount?

 * Make tables sortable

 * Make use of aggregation/map-reduce framework

 * Track withdrawals/exchange rates

 * Improve accessibility for screen readers e.g.

 * Export functionalities

 * Format amount fields on edit/new item pages

 * Reduce imported files (SASS, JS/jQuery, ...) -> selected imports

 * ...

 * Incorporate user feedback:
 	* Provide a link « create a new item » when an item has just been saved
 	* Set the base amount and currency fields (grey) after the transaction ones
 	* Possibility to enter a global amount for an item and then to split it in a different % to the participants
 	* When i click on an event, i’d like to get the « create a new item » link
 	* In the « expense summury », each item could be a link to the related item page