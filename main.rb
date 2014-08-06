require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry'

set :sessions, true

class Array
  def sample!
    delete_at rand length
  end
end

helpers do
  def create_deck(deck)
    (1..13).each do |num|
      # 1: spades 2: hearts 3: diamonds 4: clubs
      (1..4).each do |suit|
        deck << {num: num, suit: suit, val: num < 10 ? num : 10}
      end
    end
    deck
  end

  def get_card(deck)
  deck.sample!
  end

  def card_name(card)
    # Set the suit name
    case card[:suit]
    when 1
      suit_name = 'Spades'
    when 2
      suit_name = 'Hearts'
    when 3
      suit_name = 'Diamonds'
    when 4
      suit_name = 'Clubs'
    end

    # Set the card name
    case
    when card[:num] == 1
      card_name = 'Ace'
    when card[:num] <= 10
      card_name = card[:num].to_s
    when card[:num] == 11
      card_name = 'Jack'
    when card[:num] == 12
      card_name = 'Queen'
    when card[:num] == 13
      card_name = 'King'        
    end

    card_name + ' of ' + suit_name
  end

  def image_name(card)
    # Set the suit name
    case card[:suit]
    when 1
      suit_name = 'spades'
    when 2
      suit_name = 'hearts'
    when 3
      suit_name = 'diamonds'
    when 4
      suit_name = 'clubs'
    end

    # Set the card name
    case
    when card[:num] == 1
      card_name = 'ace'
    when card[:num] <= 10
      card_name = card[:num].to_s
    when card[:num] == 11
      card_name = 'jack'
    when card[:num] == 12
      card_name = 'queen'
    when card[:num] == 13
      card_name = 'king'        
    end

    suit_name + "_" + card_name + ".jpg"
  end

  def get_total(hand)
    sum = 0
    hand.each {|card| sum += card[:val]}
    if has_ace?(hand) && sum <= 11
      sum += 10
    end
    sum
  end

  def deal_cards(deck, player_hand, dealer_hand)
    player_hand << get_card(deck)
    dealer_hand << get_card(deck)
    player_hand << get_card(deck)
    dealer_hand << get_card(deck)
  end

  def has_ace?(hand)
    hand.each {|card| return true if card[:num] == 1}
    false
  end

  def is_busted?(hand)
    get_total(hand) > 21
  end

  def has_blackjack?(hand)
    get_total(hand) == 21
  end

  def decide_dealer_action(dealer_hand, user_hand)
    dealer_total = get_total(dealer_hand)
    user_total = get_total(user_hand)

    # Aces are always counted as 11 if possible
    # without the dealer going over 21
    if has_ace?(dealer_hand) && dealer_total <= 11
      dealer_total += 10
    end

    return 'h' if dealer_total < 17 || dealer_total < user_total # hit

    's' # stand
  end

  def player_wins(msg)
    session[:turn] = nil
    @winner = msg
    session[:player_cash] += session[:bet_amount] * 2
  end

  def player_loses(msg)
    session[:turn] = nil
    @loser = msg
  end

  def tie(msg)
    session[:turn] = nil
    @tie = msg
    session[:player_cash] += session[:bet_amount]
  end

  def reset_game
    session.clear
  end

  def check_for_winner(player_hand, dealer_hand, turn)
    if turn == :player
      if is_busted?(player_hand)
        player_loses "You are busted, dealer won."
      end

      if has_blackjack?(player_hand) && has_blackjack?(dealer_hand)
        tie "Two blackjacks, it's a tie!"
      end

      if has_blackjack?(player_hand)
        player_wins "Blackjack, you won!"
      end
    end

    if turn == :dealer
      if is_busted?(dealer_hand)
        player_wins "You won, dealer busted."
      end

      if has_blackjack?(dealer_hand)
        player_loses "Dealer got blackjack, you lost."
      end
    end

    if turn == :endgame
      if is_busted?(dealer_hand)
        player_wins "You won, dealer busted."
      elsif get_total(player_hand) < get_total(dealer_hand)
        player_loses "You lost."
      elsif get_total(player_hand) > get_total(dealer_hand)
        player_wins "You won."
      else
        tie "It's a tie."
      end
    end
  end
end

get '/' do
  redirect '/game'
end

get '/set_name' do
  erb :set_name
end

get '/bet' do
  if session[:player_cash] == 0
    reset_game
    redirect '/game'
  end

  erb :bet
end

get '/reset' do
  reset_game
  redirect '/game'
end

post '/bet' do
  if params[:bet_amount].to_i > session[:player_cash]
    @error = "You don't have that much money."
    halt erb(:bet)
  end

  if params[:bet_amount].to_i <= 0
    @error = "You need to bet more than that."
    halt erb(:bet)
  end

  session[:bet_amount] = params[:bet_amount].to_i
  session[:player_cash] -= session[:bet_amount]
  redirect '/game'
end  

post '/set_name' do
  if params[:player_name].strip.empty?
    @error = "Name cannot be empty"
    halt erb(:set_name)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  if session[:player_name].nil?
    session[:player_cash] = 500
    session[:bet_amount] = 0
    redirect '/set_name'
  end

  if session[:turn].nil? || (session[:turn] != :player && session[:turn] != :dealer && session[:turn] != :endgame)
    session[:turn] = :player
    session[:player_hand] = []
    redirect '/bet'
  end

  if session[:player_hand].nil? || session[:player_hand].empty?
    session[:deck] = create_deck([])
    session[:player_hand] = []
    session[:dealer_hand] = []

    deal_cards(session[:deck], session[:player_hand], session[:dealer_hand])
  end

  check_for_winner(session[:player_hand], session[:dealer_hand], session[:turn])

  erb :game
end

post '/player/hit' do
  session[:player_hand] << get_card(session[:deck])
  check_for_winner(session[:player_hand], session[:dealer_hand], session[:turn])

  erb :game, layout: false
end

post '/player/stay' do
  session[:turn] = :dealer
  if get_total(session[:dealer_hand]) >= get_total(session[:player_hand])
    session[:turn] = :endgame
  end

  check_for_winner(session[:player_hand], session[:dealer_hand], session[:turn])

  erb :game, layout: false
end

post '/dealer/next' do
  if decide_dealer_action(session[:dealer_hand], session[:player_hand]) == 'h'
    session[:dealer_hand] << get_card(session[:deck])
    if get_total(session[:dealer_hand]) >= get_total(session[:player_hand])
      session[:turn] = :endgame
    end
  else
    session[:turn] = :endgame
  end

  check_for_winner(session[:player_hand], session[:dealer_hand], session[:turn])

  erb :game, layout: false
end
