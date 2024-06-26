defmodule Ash.Test.Support.PolicySimple.Post do
  @moduledoc false
  use Ash.Resource,
    domain: Ash.Test.Support.PolicySimple.Domain,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [
      Ash.Policy.Authorizer
    ]

  policies do
    policy action_type(:read) do
      description "You can read a post if you created it or if you own the organization"
      authorize_if(expr(author.id == ^actor(:id)))
      authorize_if(expr(organization.owner_id == ^actor(:id)))
    end

    policy action_type(:create) do
      description "Admins and managers can create posts"
      authorize_if(actor_attribute_equals(:admin, true))
      authorize_if(actor_attribute_equals(:manager, true))
    end

    policy action(:say_hello) do
      authorize_if expr(^actor(:admin) == true)
      forbid_if expr(^arg(:from_an_admin?))
      authorize_if always()
    end
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :text, :string do
      public?(true)
      allow_nil?(false)
    end
  end

  actions do
    default_accept :*
    defaults [:read, :destroy, update: :*]

    create :create do
      primary? true
      argument :author, :uuid
      change manage_relationship(:author, type: :append_and_remove)

      argument :organization, :uuid
      change manage_relationship(:organization, type: :append_and_remove)
    end

    action :say_hello, :string do
      argument :to, :string, allow_nil?: false
      argument :from_an_admin?, :boolean, allow_nil?: false, default: false

      run fn input, _ ->
        if input.arguments.from_an_admin? do
          {:ok, "Hello #{input.arguments.to} from an admin!"}
        else
          {:ok, "Hello #{input.arguments.to} from an admin!"}
        end
      end
    end
  end

  relationships do
    belongs_to :organization, Ash.Test.Support.PolicySimple.Organization do
      public?(true)
    end

    belongs_to :author, Ash.Test.Support.PolicySimple.User do
      public?(true)
    end
  end
end
