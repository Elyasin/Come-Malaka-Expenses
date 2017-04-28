//= require jquery
//= require jasmine-jquery
describe("Jasmine jQuery Test", function() {
  it("works out of the box", function() {
    expect($('<input type="checkbox" checked="checked"/>')).toBeChecked();
  });
});
