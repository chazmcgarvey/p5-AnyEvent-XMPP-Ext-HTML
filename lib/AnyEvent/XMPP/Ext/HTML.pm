package AnyEvent::XMPP::Ext::HTML;
# ABSTRACT: XEP-0071: XHTML-IM (Version 1.5) for AnyEvent::XMPP

use warnings;
use strict;

use AnyEvent::XMPP::Ext;
use AnyEvent::XMPP::Namespaces qw/set_xmpp_ns_alias xmpp_ns/;

our @ISA = qw/AnyEvent::XMPP::Ext/;

=head1 SYNOPSIS

    my $c = AnyEvent::XMPP::Connection->new(...);
    $c->add_extension(my $disco = AnyEvent::XMPP::Ext::Disco->new);
    $c->add_extension(AnyEvent::XMPP::Ext::HTML->new(disco => $disco));
    
    $c->send_message(
        body => "This is plain text; same as usual.",
        html => "This is <em>XHTML</em>!",
    );

=head1 DESCRIPTION

An implementation of XEP-0071: XHTML-IM for HTML-formatted messages.

=head1 CAVEATS

HTML messages are not validated nor escaped, so it is your responsibility to
use valid XHTML-IM tags and to close them properly.

=method new

Creates a new extension handle.  It takes an optional C<disco> argument which
is a L<AnyEvent::XMPP::Ext::Disco> object for which this extension will be
enabled.

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = bless { @_ }, $class;
    $self->init;
    $self;
}

=method init

Initialize the extension.  This does not need to be called externally.

=cut

sub init {
    my $self = shift;

    set_xmpp_ns_alias(xhtml_im => 'http://jabber.org/protocol/xhtml-im');
    set_xmpp_ns_alias(xhtml => 'http://www.w3.org/1999/xhtml');

    $self->{disco}->enable_feature($self->disco_feature) if defined $self->{disco};

    $self->{cb_id} = $self->reg_cb(
        send_message_hook => sub {
            my ($self, $con, $id, $to, $type, $attrs, $create_cb) = @_;

            return unless exists $attrs->{html};
            my $html = delete $attrs->{html};

            push @$create_cb, sub {
                my ($w) = @_;

                $w->addPrefix(xmpp_ns('xhtml_im'), '');
                $w->startTag([xmpp_ns('xhtml_im'), 'html']);
                if (ref($html) eq 'HASH') {
                    for (keys %$html) {
                        $w->addPrefix(xmpp_ns('xhtml'), '');
                        $w->startTag([xmpp_ns('xhtml'), 'body'], ($_ ne '' ? ([xmpp_ns('xml'), 'lang'] => $_) : ()));
                        $w->raw($html->{$_});
                        $w->endTag;
                    }
                } else {
                    $w->addPrefix(xmpp_ns('xhtml'), '');
                    $w->startTag([xmpp_ns('xhtml'), 'body']);
                    $w->raw($html);
                    $w->endTag;
                }
                $w->endTag;
            };
        },
    );
}

sub disco_feature {
    xmpp_ns('xhtml_im');
}

sub DESTROY {
    my $self = shift;
    $self->unreg_cb($self->{cb_id});
}

1;
