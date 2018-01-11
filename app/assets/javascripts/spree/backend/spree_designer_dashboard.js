(function () {
    console.log("hello")
    var t = document.createElement('script');
    t.setAttribute("data-cordial-track-key", "scountandnimble");
    t.setAttribute("data-cordial-url", "track.cordial.io");
    t.setAttribute("data-auto-track", false);
    t.src = '//track.cordial.io/track.js';
    t.async = true;
    t.onload = cordialLoaded;
    document.body.appendChild(t);
})();

function cordialLoaded () {

    <% if spree_current_user %>
    cordial.identify("<%= spree_current_user.email %>");
    console.log("hello")
    cordial.contact(<%= spree_current_user.cordial_contact_data.to_json.html_safe %>);
    <% end %>
}
console.log("asdasdas")