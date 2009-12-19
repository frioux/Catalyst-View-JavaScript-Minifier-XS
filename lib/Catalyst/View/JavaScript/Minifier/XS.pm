package Catalyst::View::JavaScript::Minifier::XS;

# ABSTRACT: Minify your served JavaScript files

use autodie;
use Moose;
extends 'Catalyst::View';

use JavaScript::Minifier::XS qw/minify/;
use Path::Class::File;
use URI;

has stash_variable => (
   is => 'ro',
   isa => 'Str',
   default => 'js',
);

has path => (
   is => 'ro',
   isa => 'Str',
   default => 'js',
);

has subinclude => (
   is => 'ro',
   isa => 'Bool',
   default => undef,
);

sub process {
   my ($self,$c) = @_;

   my $original_stash = $c->stash->{$self->stash_variable};
   my @files = $self->_expand_stash($original_stash);

   $c->res->content_type('text/javascript');

   push @files, $self->_subinclude($c, $original_stash, @files);

   my $home = $self->config->{INCLUDE_PATH} || $c->path_to('root');
   @files = map {
      $_ =~ s/\.js$//;
      Path::Class::File->new( $home, $self->path, "$_.js" );
   } grep { defined $_ && $_ ne '' } @files;

   my @output = $self->_combine_files($c, \@files);

   $c->res->body( $self->_minify($c, \@output) );
}

sub _subinclude {
   my ( $self, $c, $original_stash, @files ) = @_;

   return unless $self->subinclude && $c->request->headers->referer;

   unless ( $c->request->headers->referer ) {
      $c->log->debug('javascripts called from no referer sending blank');
      $c->res->body( q{ } );
      $c->detach();
   }

   my $referer = URI->new($c->request->headers->referer);

   if ( $referer->path eq '/' ) {
      $c->log->debug(q{we can't take js from index as it's too likely to enter an infinite loop!});
      return;
   }

   $c->forward('/'.$referer->path);
   $c->log->debug('js taken from referer : '.$referer->path);

   return $self->_expand_stash($c->stash->{$self->stash_variable})
      if $c->stash->{$self->stash_variable} ne $original_stash;
}

sub _minify {
   my ( $self, $c, $output ) = @_;

   if ( @{$output} ) {
      return $c->debug
         ? join q{ }, @{$output}
         : minify(join q{ }, @{$output} )
   } else {
      return q{ };
   }
}

sub _combine_files {
   my ( $self, $c, $files ) = @_;

   my @output;
   for my $file (@{$files}) {
      $c->log->debug("loading js file ... $file");
      open my $in, '<', $file;
      for (<$in>) {
         push @output, $_;
      }
      close $in;
   }
   return @output;
}

sub _expand_stash {
   my ( $self, $stash_var ) = @_;

   if ( $stash_var ) {
      return ref $stash_var eq 'ARRAY'
         ? @{ $stash_var }
	 : split /\s+/, $stash_var;
   }

}

1;

=pod

=head1 SYNOPSIS

 # creating MyApp::View::JavaScript
 ./script/myapp_create.pl view JavaScript JavaScript::Minifier::XS

 # in your controller file, as an action
 sub js : Local {
    my ( $self, $c ) = @_;

    # loads root/js/script1.js and root/js/script2.js
    $c->stash->{js} = [qw/script1 script2/];

    $c->forward('View::JavaScript');
 }

 # in your html
 <script type="text/javascript" src="/js"></script>

=head1 DESCRIPTION

Use your minified js files as a separated catalyst request. By default they
are read from C<< $c->stash->{js} >> as array or string.  Also note that this
does not minify the javascript if the server is started in development mode.

=head1 CONFIG VARIABLES

=over 2

=item stash_variable

sets a different stash variable from the default C<< $c->stash->{js} >>

=item path

sets a different path for your javascript files

default : js

=item subinclude

setting this to true will take your js files (stash variable) from your referer
action

 # in your controller
 sub action : Local {
    my ( $self, $c ) = @_;

    # load exclusive.js only when /action is loaded
    $c->stash->{js} = "exclusive";
 }

This could be very dangerous since it's using
C<< $c->forward($c->request->headers->referer) >>. It doesn't work with the
index action!

default : false

=back

=cut

=head1 SEE ALSO

L<JavaScript::Minifier::XS>

