use Test::More tests => 6;
BEGIN { use_ok( 'Math::DyckWords' ) };

my @words = Math::DyckWords::dyck_words_by_lex( 5 );

# there shold be 42 Dyck Words of length 5
ok( scalar @words == 42, "dyck-words-by-lex" );

@words = Math::DyckWords::dyck_words_by_position( 5 );
ok( scalar @words == 42, "dyck-words-by-position" );

@words = Math::DyckWords::dyck_words_by_swap( 5 );
ok( scalar @words == 42, "dyck-words-by-swap" );

my $rank = Math::DyckWords::ranking( '0011000111' );
ok( $rank == 19, "ranking" );

my $word = Math::DyckWords::unranking( 5, 19 );
ok( $word eq '0011000111', "unranking" );

