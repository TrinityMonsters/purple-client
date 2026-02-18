path :v1 do
  path :warehouses, method: :get do
    root_method :warehouses

    response :ok do
      body(
        warehouses: [
          {
            id: Integer,
            name: String
          }
        ]
      )
    end
  end
end
