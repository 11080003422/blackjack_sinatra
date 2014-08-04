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

  def initialize_game(deck, player_hand, dealer_hand)
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
end

get '/' do
  if session[:player_name].to_s == ''
    redirect '/set_name'
  else
    redirect '/game'
  end
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  if session[:turn].nil? || (session[:turn] != :player && session[:turn] != :dealer)
    session[:turn] = :player
    session[:player_hand] = []
  end

  if session[:player_name].nil?
    redirect '/set_name'
  end

  if session[:player_hand].nil? or session[:player_hand].empty?
    session[:deck] = create_deck([])
    session[:player_hand] = []
    session[:dealer_hand] = []

    initialize_game(session[:deck], session[:player_hand], session[:dealer_hand])
  end

  if session[:turn] == :player
    if is_busted?(session[:player_hand])
      session[:turn] = nil
      @error = "You are busted, dealer won."
    end

    if has_blackjack?(session[:player_hand])
      session[:turn] = nil
      @success = "Blackjack, you won!"
    end
  end

  erb :game
end

post '/player/hit' do
  session[:player_hand] << get_card(session[:deck])
  redirect '/game'
end

post '/player/stay' do
  session[:turn] = :dealer
  redirect '/game'
end



