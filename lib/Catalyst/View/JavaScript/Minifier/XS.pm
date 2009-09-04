package Catalyst::View::JavaScript::Minifier::XS;

use warnings;
use strict;

use parent qw/Catalyst::View/;

our $VERSION = '0.04';

use JavaScript::Minifier::XS qw/minify/;
use Path::Class::File;
use URI;

=head1 NAME

Catalyst::View::JavaScript::Minifier::XS - Concenate and minify your JavaScript files.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    # creating MyApp::View::JavaScript
    ./script/myapp_create.pl view JavaScript JavaScript::Minifier::XS

	# in your controller file, as an action
    sub js : Local {
		my ( $self, $c ) = @_;

		$c->stash->{js} = [qw/script1 script2/]; # loads root/js/script1.js and root/js/script2.js

		$c->forward("View::JavaScript");
    }

	# in your html template use
	<script type="text/javascript" src="/js"></script>

=head1 DESCRIPTION

Use your minified js files as a separated catalyst request. By default they are read from C<< $c->stash->{js} >> as array or string.

=head1 CONFIG VARIABLES

=over 2

=item stash_variable

sets a different stash variable from the default C<< $c->stash->{js} >>

=item path

sets a different path for your javascript files

default : js

=item subinclude

setting this to true will take your js files (stash variable) from your referer action

	# in your controller
	sub action : Local {
		my ( $self, $c ) = @_;

		$c->stash->{js} = "exclusive"; # loads exclusive.js only when /action is loaded
	}

This could be very dangerous since it's using C<< $c->forward($c->request->headers->referer) >>. It doesn't work with the index action!

default : false

=back

=cut

__PACKAGE__->mk_accessors(qw(stash_variable path subinclude));

__PACKAGE__->config(stash_variable => 'js', path => 'js', subinclude => 0);


sub process {
	my ($self,$c) = @_;

	my $path = $self->path;
	my $variable = $self->stash_variable;
	my @files = ();

	my $original_stash = $c->stash->{$variable};

	# setting the return content type
	$c->res->content_type('text/javascript');

	# turning stash variable into @files
	if ( $c->stash->{$variable} ) {
		@files = ( ref $c->stash->{$variable} eq 'ARRAY' ? @{ $c->stash->{$variable} } : split /\s+/, $c->stash->{$variable} );
	}

	# No referer we won't show anything
	if ( ! $c->request->headers->referer ) {
		$c->log->debug('javascripts called from no referer sending blank');
		$c->res->body( q{ } );
		$c->detach();
	}

	# If we have subinclude ON then we should run the action and see what it left behind
	if ( $self->subinclude ) {
		my $base = $c->request->base;
		if ( $c->request->headers->referer ) {
			my $referer = URI->new($c->request->headers->referer);
			if ( $referer->path ne '/' ) {
				$c->forward('/'.$referer->path);
				$c->log->debug('js taken from referer : '.$referer->path);
				if ( $c->stash->{$variable} ne $original_stash ) {
					# adding other files returned from $c->forward to @files ( if any )
					push @files, ( ref $c->stash->{$variable} eq 'ARRAY' ? @{ $c->stash->{$variable} } : split /\s+/, $c->stash->{$variable} );
				}
			} else {
				# well for now we can't get js files from index, because it's indefinite loop
				$c->log->debug(q{we can't take js from index, it's too dangerous!});
			}
		}
	}

	my $home = $self->config->{INCLUDE_PATH} || $c->path_to('root');
	@files = map {
		my $file = $_;
		$file =~ s/\.js$//;
		Path::Class::File->new( $home, "$path", "$file.js" );
	} @files;

	# combining the files
	my @output = ();
	for my $file ( @files ) {
		$c->log->debug("loading js file ... $file");
		open my $in, '<', "$file";
		for ( <$in> ) {
			push @output, $_;
		}
		close $in;
	}

	if ( @output ) {
		# minifying them if any files loaded at all
		$c->res->body(
                   $c->debug
                      ? join q{ },@output
                      : minify(join q{ }, @output )
                );
	} else {
		$c->res->body( q{ } );
	}
}

=head1 SEE ALSO

L<Catalyst> , L<Catalyst::View>, L<JavaScript::Minifier::XS>

=head1 AUTHOR

Ivan Drinchev C<< <drinchev at gmail.com> >>

Arthur Axel "fREW" Schmidt <frioux@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-JavaScript-minifier-xs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-JavaScript-Minifier-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ivan Drinchev, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::View::JavaScript::Minifier::XS
