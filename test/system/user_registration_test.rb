require "application_system_test_case"

class UserRegistrationTest < ApplicationSystemTestCase
  test "user can sign up and be redirect to home page" do
    visit new_user_registration_path

    assert_selector "h2", text: "Crie sua conta"

    fill_in "First name", with: "John"
    fill_in "Last name", with: "Doe"
    fill_in "Phone", with: "+5511999999999"
    fill_in "Cpf", with: "12345678901"
    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"

    click_button "Criar conta"

    assert_current_path users_path

    assert_text "Welcome! You have signed up successfully"
  end
end
