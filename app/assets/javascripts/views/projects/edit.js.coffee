class window.StaffPlan.Views.Projects.Edit extends Support.CompositeView
  
  tagName: "form"
  className: "form-horizontal padding-top-40"

  initialize: ->
    @newClient = false
    @clients = @options.clients
    @currentUser = @options.currentUser
     
  events: ->
    "change select#client-picker": "clientSelectionChanged"
    "click div.form-actions a[data-action=update]": "updateUser"


  updateUser: ->
    formValues = @getFormValues("input, select")
    if @newClient
      # First create the client
      @clients.create { name: formValues.client.name },
        success: (model, response) =>
          @updateProjectAndAssignment model.id, formValues
        error: (model, response) ->
    else
      @updateProjectAndAssignment formValues.client.id, formValues

  updateProjectAndAssignment: (clientId, formValues) ->
    # Each model should expose a whitelistedAttributes so that we only transmit what's needed
    projectAttributes = _.extend (_.pick formValues.project, ['name', 'active', 'payment_frequency', 'cost']),
      company_id: window.StaffPlan.currentCompany.id
      client_id: clientId
    @model.save projectAttributes,
      success: (model, response) =>
        # Each model should expose a whitelistedAttributes so that we only transmit what's needed
        assignmentAttributes =
          project_id: model.id
          user_id: @currentUser.id
          proposed: formValues.project.proposed
        assignment = @currentUser.getAssignments().detect (a) =>
          a.get('project_id') is @model.id
        assignment.save assignmentAttributes,
          success: (model, response) ->
          error: (model, response) ->
      error: (model, response) ->


  clientSelectionChanged: (event) ->
    newClientSelected = $(event.currentTarget).find("option:selected").hasClass "new-client"
    if @newClient isnt newClientSelected
      @$el.find(".initially-hidden").fadeToggle "slow"
    @newClient = newClientSelected

  
  # TODO: Only handles base elements like inputs and selects
  getFormValues: (selector) ->
    _.reduce @$el.find(selector), (values, formElement) =>
      values[$(formElement).data('model')][$(formElement).data('attribute')] = @getFormElementValue formElement
      values
    , _.chain(@$el.find selector)
        .map( (e) ->
          $(e).data "model"
        )
        .uniq()
        .reduce( (m, e) ->
          m[e] = {}
          m
        , {}
        )
        .value()
  
  getFormElementValue: (element) ->
    switch $(element).prop('tagName').toLowerCase()
      when "select"
        return $(element).val()
      when "input"
        switch $(element).attr "type"
          when "number", "text"
            return $(element).val()
          when "radio"
            $(element).closest('radiogroup').find('input[type=radio]:checked').val()
          when "checkbox"
            return $(element).prop "checked"
      
  populateFields: ->
    unless @model.isNew()
      projectAssignment = StaffPlan.assignments.detect (a) =>
        a.get('project_id') is @model.id and a.get('user_id') is StaffPlan.currentUser.id

      attrs = _.extend @model.toJSON(),
        proposed: projectAssignment?.get("proposed") or false
      
      @$el
        .find("select[data-model=client][data-attribute=id]")
        .val(attrs.client_id)
      
      _.each ["name", "cost"], (prop) =>
        @$el
          .find("[data-model=project][data-attribute=#{prop}]")
          .val(attrs[prop])
      
          
      @$el
        .find("radiogroup[data-model=project][data-attribute=payment_frequency]")
        .find("input[type=radio]")
        .prop("checked", false)
      @$el
        .find("radiogroup[data-model=project][data-attribute=payment_frequency]")
        .find("input[type=radio][value=#{attrs.payment_frequency}]")
        .prop("checked", true)
      
      _.each ["proposed", "active"], (prop) =>
        @$el
          .find("[data-model=project][data-attribute=#{prop}]")
          .prop "checked", attrs[prop]
  render: ->
    @$el.append StaffPlan.Templates.Projects.edit
      clients: @clients.map (client) -> client.toJSON()
    @$el.find(".initially-hidden").hide()
    @populateFields()
    @$el.appendTo "section.main"

    @